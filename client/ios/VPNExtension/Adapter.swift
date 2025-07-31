import Foundation
import Network
import NetworkExtension
import os

/// State of Adapter.
enum State {
    /// Tunnel is running.
    case running
    /// Tunnel is stopped.
    case stopped
    /// Tunnel is temporary unavaiable due to device being offline.
    case dormant
}

final class Adapter /*: Sendable*/ {
    /// Packet tunnel provider.
    private weak var packetTunnelProvider: NEPacketTunnelProvider?
    /// BortingTun tunnel
    private var tunnel: Tunnel?
    /// UDP endpoint
    private var endpoint: Network.NWEndpoint?
    /// Server connection
    private var connection: NWConnection?
    /// Network routes monitor.
    private var networkMonitor: NWPathMonitor?
    /// Keep alive timer
    private var keepAliveTimer: Timer?
    /// Logging
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Adapter")
    /// Adapter state.
    private var state: State = .stopped
    private var reconnectOnExpiry: Bool = false

    /// Designated initializer.
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    init(with packetTunnelProvider: NEPacketTunnelProvider) {
        self.packetTunnelProvider = packetTunnelProvider
    }

    deinit {
        self.stop()
    }

    func start(tunnelConfiguration: TunnelConfiguration) throws {
        if let _ = tunnel {
            logger.info("Cleaning exiting Tunnel")
            tunnel = nil
            connection = nil
        }

        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.networkPathUpdate(path: path)
        }
        networkMonitor.start(queue: .main)
        self.networkMonitor = networkMonitor

        logger.info("Initializing Tunnel")
        tunnel = try Tunnel.init(
            privateKey: tunnelConfiguration.interface.privateKey,
            serverPublicKey: tunnelConfiguration.peers[0].publicKey,
            presharedKey: tunnelConfiguration.peers[0].preSharedKey,
            keepAlive: tunnelConfiguration.peers[0].persistentKeepAlive,
            index: 0
        )

        if tunnelConfiguration.peers[0].preSharedKey != nil {
            logger.info("Using pre-shared key, the tunnel won't be re-established on expiry")
            reconnectOnExpiry = false
        } else {
            logger.info("No pre-shared key, the tunnel will be re-established on expiry")
            reconnectOnExpiry = true
        }

        logger.info("Connecting to endpoint")
        guard let endpoint = tunnelConfiguration.peers[0].endpoint else {
            logger.error("Endpoint is nil")
            return
        }
        self.endpoint = endpoint.asNWEndpoint()
        initEndpoint()

        logger.info("Sniffing packets")
        readPackets()

        state = .running
    }

    func stop() {
        logger.info("Stopping Adapter")
        connection?.cancel()
        connection = nil
        tunnel = nil
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        // Cancel network monitor
        networkMonitor?.cancel()
        networkMonitor = nil
        state = .stopped
        logger.info("Tunnel stopped")
    }

    private func handleTunnelResult(_ result: TunnelResult) {
        switch result {
            case .done:
                // Nothing to do.
                break
            case .err(let error):
                logger.error("Tunnel error \(error, privacy: .public)")
                switch error {
                    case .InvalidAeadTag:
                        logger.error("Invalid pre-shared key; stopping tunnel")
                        // The correct way is to call the packet tunnel provider, if there is one.
                        if let provider = packetTunnelProvider {
                            provider.cancelTunnelWithError(error)
                        } else {
                            stop()
                        }
                    case .ConnectionExpired:
                        packetTunnelProvider?.reasserting = true
                        if self.reconnectOnExpiry {
                            logger.error("Connecion has expired; re-connecting")
                            initEndpoint()
                            logger.info("Finished re-connecting")
                        } else {
                            logger.error("Connection has expired; stopping tunnel")
                            let defaults = UserDefaults(suiteName: suiteName)
                            defaults?.set(
                                TunnelStopError.mfaSessionExpired.rawValue
                                , forKey: "lastTunnelError")
                            if let provider = packetTunnelProvider {
                                provider.cancelTunnelWithError(error)
                            } else {
                                stop()
                            }
                        }
                        packetTunnelProvider?.reasserting = false
                    default:
                        break
                }
            case .writeToNetwork(let data):
                sendToEndpoint(data: data)
            case .writeToTunnelV4(let data):
                packetTunnelProvider?.packetFlow.writePacketObjects([
                    NEPacket(data: data,protocolFamily: sa_family_t(AF_INET))])
            case .writeToTunnelV6(let data):
                packetTunnelProvider?.packetFlow.writePacketObjects([
                    NEPacket(data: data, protocolFamily: sa_family_t(AF_INET6))])
        }
    }

    /// Initialise UDP connection to endpoint.
    private func initEndpoint() {
        guard let endpoint = endpoint else { return }

        logger.info("Init Endpoint")
        // Cancel previous connection
        connection?.cancel()
        connection = nil

        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        let connection = NWConnection.init(to: endpoint, using: params)
        connection.stateUpdateHandler = { [weak self] state in
            self?.endpointStateChange(state: state)
        }

        connection.start(queue: .main)
        self.connection = connection
    }

    /// Setup UDP connection to endpoint. This method should be called when UDP connection is ready to send and receive.
    private func setupEndpoint() {
        logger.info("Setup endpoint")

        // Send initial handshake packet
        if let tunnel = self.tunnel {
            handleTunnelResult(tunnel.forceHandshake())
        }
        logger.info("Receiving UDP from endpoint")
        receive()

        // Use Timer to send keep-alive packets.
        keepAliveTimer?.invalidate()
        logger.info("Creating keep-alive timer")
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] timer in
            guard let self = self, let tunnel = self.tunnel else { return }
            self.handleTunnelResult(tunnel.tick())
        }
        keepAliveTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    /// Send packets to UDP endpoint.
    private func sendToEndpoint(data: Data) {
        guard let connection = connection else { return }
        if connection.state == .ready {
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("UDP connection send error: \(error, privacy: .public)")
                }
            })
        } else {
            logger.warning("UDP connection not ready to send")
        }
    }

    /// Handle UDP packets from the endpoint.
    private func receive() {
        connection?.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            if let data = data, let tunnel = self.tunnel {
                self.handleTunnelResult(tunnel.read(src: data))
            }
            if error == nil {
                // continue receiving
                self.receive()
            }
        }
    }

    /// Read tunnel packets.
    private func readPackets() {
        guard let tunnel = self.tunnel else { return }

        // Packets received to the tunnel's virtual interface.
        packetTunnelProvider?.packetFlow.readPacketObjects { packets in
            for packet in packets  {
                self.handleTunnelResult(tunnel.write(src: packet.data))
            }
            // continue reading
            self.readPackets()
        }
    }

    /// Handle UDP connection state changes.
    private func endpointStateChange(state: NWConnection.State) {
        logger.debug("UDP connection state: \(String(describing: state), privacy: .public)")
        switch state {
            case .ready:
                setupEndpoint()
            case .failed(let error):
                logger.error("Failed to establish endpoint connection: \(error)")
                // The correct way is to call the packet tunnel provider, if there is one.
                if let provider = packetTunnelProvider {
                    provider.cancelTunnelWithError(error)
                } else {
                    stop()
                }
            default:
                break
        }
    }

    /// Handle network path updates.
    private func networkPathUpdate(path: Network.NWPath) {
        if path.status == .unsatisfied {
            if state == .running {
                logger.warning("Unsatisfied network path: going dormant")
                connection?.cancel()
                connection = nil
                state = .dormant
            }
        } else {
            if state == .dormant {
                logger.warning("Satisfied network path: going running")
                initEndpoint()
                state = .running
            }
        }
    }
}
