import NetworkExtension
import os
import Network

enum VPNEventType: String {
    case tunnelUp = "tunnel_up"
    case tunnelDown = "tunnel_down"
    case tunnelError = "tunnel_error"
    case connectionStatusChanged = "connection_status_changed"
    case bytesTransferred = "bytes_transferred"
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var logger = Logger(subsystem: "net.defguard.mobile.Client", category: "VPNExtension")

    private lazy var adapter: Adapter = {
        return Adapter(with: self)
    }()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelConfig = extractTunnelConfiguration() else {
            let error = NSError(domain: "VPNExtension", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Tunnel configuration is missing or invalid."])
            self.logger.log(level: .error, "Tunnel configuration is missing or invalid.")
            completionHandler(error)
            return
        }

        self.logger.log("Starting tunnel with configuration: \(String(describing: tunnelConfig), privacy: .public)")

        guard let endpoint = Endpoint(from: tunnelConfig.endpoint) else {
            let error = NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint format: \(tunnelConfig.endpoint)"])
            self.logger.log(level: .error, "Invalid endpoint format: \(tunnelConfig.endpoint, privacy: .public)")
            completionHandler(error)
            return
        }

        let tunnelConfiguration = TunnelConfiguration(fromStartData: tunnelConfig)
        let networkSettings = tunnelConfiguration.asNetworkSettings()

        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.logger.log("Set tunnel network settings returned an error \(error, privacy: .public)")
                completionHandler(error)
                return
            }

            do {
                try self.adapter.start(tunnelConfiguration: tunnelConfiguration)
            } catch {
                self.logger.log(level: .error, "Failed to start adapter with error: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
                return
            }

            self.logger.log("Tunnel started successfully")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        self.logger.log("\(#function)")
        self.adapter.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        self.logger.log("\(#function)")
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        self.logger.log("\(#function)")
        completionHandler()
    }

    override func wake() {
        self.logger.log("\(#function)")
    }

    // MARK: - Helpers

    private func extractTunnelConfiguration() -> TunnelStartData? {
        guard let providerConfig = (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration as? [String: Any] else {
            return nil
        }
        return try? TunnelStartData.from(dictionary: providerConfig)
    }
}
