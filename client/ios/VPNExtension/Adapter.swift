//
//  Adapter.swift
//  Pods
//
//  Created by Aleksander on 04/07/2025.
//

import Foundation
import Network
import NetworkExtension
import os

public class Adapter {
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
    //        // Shutdown the tunnel
    //        if case .started(let handle, _) = self.state {
    //            wgTurnOff(handle)
    //        }
    //    }

    public func start(tunnelConfiguration: TunnelConfiguration) {
        // TODO: kill exising tunnel
        print("Initalizing Tunnel...")
        tunnel = Tunnel.init(
            privateKey: tunnelConfiguration.interface.privateKey,
            serverPublicKey: tunnelConfiguration.peers[0].publicKey,
            keepAlive: tunnelConfiguration.peers[0].persistentKeepAlive,
            index: 0
        )

        print("Connecting to endpoint...")
        let endpoint = NWEndpoint.hostPort(host: tunnelConfiguration.interface.endpoint.host, port: tunnelConfiguration.interface.endpoint.port)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        connection = NWConnection.init(to: endpoint, using: params)


        connection?.stateUpdateHandler = { state in
            print("State: \(state)")
        }
        print("Receiving UDP from endpoint...")
        connection?.start(queue: .main)
        // Send initial handshake packet
        if let tunnel = tunnel {
            handleTunnelResult(tunnel.forceHandshake())
        }
        receive()

        print("Sniffing packets...")
        readPackets()
    }
    
    public func stop() {
        print("Stopping Adapter...")
        connection?.cancel()
        connection = nil
        tunnel = nil
    }
    
    public func isConnected() -> Bool {
        return connection?.state == .ready
    }
    
    private func handleTunnelResult(_ result: TunnelResult) {
        switch result {
            case .done:
                os_log("done")
                break
            case .err(let error):
                os_log("packet map error %{public}@", String(describing: error))
                break
            case .writeToNetwork(let data):
                os_log("write to network")
                sendToEndpoint(data: data)
            case .writeToTunnelV4(let data):
                os_log("write to tunnel v4")
                self.packetTunnelProvider?.packetFlow.writePacketObjects([NEPacket(data: data, protocolFamily: sa_family_t(AF_INET))])
            case .writeToTunnelV6(let data):
                os_log("write to tunnel v6")
                self.packetTunnelProvider?.packetFlow.writePacketObjects([NEPacket(data: data, protocolFamily: sa_family_t(AF_INET6))])
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
        guard let connection = connection else {
            return
        }
        connection.receiveMessage { data, context, isComplete, error in
            if let data = data, let tunnel = self.tunnel {
                os_log("Received from endpoint: \(data.count)")
                self.handleTunnelResult(tunnel.read(src: data))
            }
            if error == nil {
                self.receive() // continue receiving
            } else {
                os_log("ERRROR: \(error)")
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
