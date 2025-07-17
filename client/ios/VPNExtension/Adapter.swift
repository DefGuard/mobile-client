import Foundation
import Network
import NetworkExtension
import os

final class Adapter /*: Sendable*/ {
    /// Packet tunnel provider.
    private weak var packetTunnelProvider: NEPacketTunnelProvider?
    /// BortingTun tunnel
    private var tunnel: Tunnel?
    /// Server connection
    private var connection: NWConnection?
    /// Keep alive timer
    private var keepAliveTimer: Timer?

    /// Designated initializer.
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    public init(with packetTunnelProvider: NEPacketTunnelProvider) {
        self.packetTunnelProvider = packetTunnelProvider
    }

    public func start(tunnelConfiguration: TunnelConfiguration) throws {
        if let _ = tunnel {
            os_log("Cleaning exiting Tunnel...")
            self.tunnel = nil
            self.connection = nil
        }

        os_log("Initializing Tunnel...")
        tunnel = try Tunnel.init(
            privateKey: tunnelConfiguration.interface.privateKey,
            serverPublicKey: tunnelConfiguration.peers[0].publicKey,
            presharedKey: tunnelConfiguration.peers[0].preSharedKey,
            keepAlive: tunnelConfiguration.peers[0].persistentKeepAlive,
            index: 0
        )

        os_log("Connecting to endpoint...")
        guard let endpoint = tunnelConfiguration.peers[0].endpoint else {
            os_log("Endpoint is nil")
            return
        }
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        connection = NWConnection.init(to: endpoint.asNWEndpoint(), using: params)

        //connection?.stateUpdateHandler = { state in
        //    print("UDP connection state: \(state)")
        //}
        os_log("Receiving UDP from endpoint...")
        connection?.start(queue: .main)
        // Send initial handshake packet
        if let tunnel = tunnel {
            handleTunnelResult(tunnel.forceHandshake())
        }
        receive()

        // Use Timer to send keep-alive packets.
        keepAliveTimer?.invalidate()
        os_log("Creating keep-alive timer...")
        let timer = Timer(timeInterval: 0.25, repeats: true) { timer in
            guard let tunnel = self.tunnel else { return }
            self.handleTunnelResult(tunnel.tick())
        }
        keepAliveTimer = timer
        RunLoop.main.add(timer, forMode: .common)

        os_log("Sniffing packets...")
        readPackets()
    }

    public func stop() {
        os_log("Stopping Adapter...")
        connection?.cancel()
        connection = nil
        tunnel = nil
    }

    private func handleTunnelResult(_ result: TunnelResult) {
        switch result {
            case .done:
                break
            case .err(_):
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

    func sendToEndpoint(data: Data) {
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                os_log("Send error: \(error)")
            }
        })
    }

    /// Handle UDP packets from the endpoint.
    private func receive() {
        guard let connection = connection else { return }
        connection.receiveMessage { data, context, isComplete, error in
            if let data = data, let tunnel = self.tunnel {
                self.handleTunnelResult(tunnel.read(src: data))
            }
            if error == nil {
                self.receive() // continue receiving
            }
        }
    }

    func readPackets() {
        guard let tunnel = self.tunnel else { return }

        // Packets received to the tunnel's virtual interface.
        packetTunnelProvider?.packetFlow.readPacketObjects { packets in
            for packet in packets  {
                self.handleTunnelResult(tunnel.write(src: packet.data))
            }
            self.readPackets()
        }
    }
}
