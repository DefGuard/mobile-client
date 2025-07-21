import Foundation
import Network
import NetworkExtension
import os

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

    /// Designated initializer.
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    public init(with packetTunnelProvider: NEPacketTunnelProvider) {
        self.packetTunnelProvider = packetTunnelProvider
    }

    deinit {
        self.stop()
    }

    public func start(tunnelConfiguration: TunnelConfiguration) throws {
        if let _ = tunnel {
            logger.info("Cleaning exiting Tunnel...")
            tunnel = nil
            connection = nil
        }

        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.networkPathUpdate(path: path)
        }
        networkMonitor.start(queue: .main)
        self.networkMonitor = networkMonitor

        logger.info("Initializing Tunnel...")
        tunnel = try Tunnel.init(
            privateKey: tunnelConfiguration.interface.privateKey,
            serverPublicKey: tunnelConfiguration.peers[0].publicKey,
            presharedKey: tunnelConfiguration.peers[0].preSharedKey,
            keepAlive: tunnelConfiguration.peers[0].persistentKeepAlive,
            index: 0
        )

        logger.info("Connecting to endpoint...")
        guard let endpoint = tunnelConfiguration.peers[0].endpoint else {
            logger.error("Endpoint is nil")
            return
        }
        self.endpoint = endpoint.asNWEndpoint()
        initEndpoint()

        logger.info("Sniffing packets...")
        readPackets()
    }

    public func stop() {
        logger.info("Stopping Adapter...")
        connection?.cancel()
        connection = nil
        tunnel = nil
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        // Cancel network monitor
        networkMonitor?.cancel()
        networkMonitor = nil
        logger.info("Tunnel stopped")
    }

    private func handleTunnelResult(_ result: TunnelResult) {
        switch result {
            case .done:
                break
            case .err(let error):
                logger.error("Tunnel error \(String(describing: error))")
                if error == WireGuardError.connectionExpired {
                    logger.error("Connecion has expired - stopping the tunnel")
                    stop()
                }
                break
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

    /// Setup UDP connection to endpoint. This method should called when UDP connection is ready to send and receive.
    private func setupEndpoint() {
        logger.info("Setup Endpoint")

        // Send initial handshake packet
        if let tunnel = self.tunnel {
            handleTunnelResult(tunnel.forceHandshake())
        }
        logger.info("Receiving UDP from endpoint...")
        receive()

        // Use Timer to send keep-alive packets.
        keepAliveTimer?.invalidate()
        logger.info("Creating keep-alive timer...")
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
            default:
                break
        }
    }

    /// Handle network path updates.
    private func networkPathUpdate(path: Network.NWPath) {
        if path.status == .unsatisfied {
            logger.warning("Unsatisfied network path: going dormant")
            connection?.cancel()
            connection = nil
        } else {
            logger.warning("Satisfied network path: going running")
            initEndpoint()
        }
    }
}
