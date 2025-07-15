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

    /// Designated initializer.
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    public init(with packetTunnelProvider: NEPacketTunnelProvider) {
        self.packetTunnelProvider = packetTunnelProvider
    }

    //    deinit {
    //        // Shut the tunnel down
    //        if case .started(let handle, _) = self.state {
    //        }
    //    }

    public func start(tunnelConfiguration: TunnelConfiguration) throws {
        // TODO: kill exising tunnel
        if let tunnel = tunnel {
            os_log("Cleaning exiting Tunnel...")
        }

        os_log("Initalizing Tunnel...")
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

        //        connection?.stateUpdateHandler = { state in
        //            print("UDP connection state: \(state)")
        //        }
        os_log("Receiving UDP from endpoint...")
        connection?.start(queue: .main)
        // Send initial handshake packet
        if let tunnel = tunnel {
            handleTunnelResult(tunnel.forceHandshake())
        }
        receive()

        os_log("Sniffing packets...")
        readPackets()
    }

    public func stop() {
        print("Stopping Adapter...")
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
            } else {
                os_log("Message sent")
            }
        })
    }

    /// Handle UDP packets from the endpoint.
    private func receive() {
        guard let connection = connection else { return }
        connection.receiveMessage { data, context, isComplete, error in
            if let data = data, let tunnel = self.tunnel {
                print("Received from endpoint: \(data.count)")
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
                os_log("Received packet \(packet.data.count)")
                self.handleTunnelResult(tunnel.write(src: packet.data))
            }
            self.readPackets()
        }
    }
}
