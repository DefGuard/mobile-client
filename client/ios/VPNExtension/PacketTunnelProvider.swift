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
    /// Logging
    private var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "PacketTunnelProvider"
    )

    private lazy var adapter: Adapter = {
        return Adapter(with: self)
    }()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelConfig = extractTunnelConfiguration() else {
            let error = NSError(domain: "VPNExtension", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Tunnel configuration is missing or invalid."])
            logger.error("Tunnel configuration is missing or invalid.")
            completionHandler(error)
            return
        }

        logger.log("Starting tunnel with configuration: \(String(describing: tunnelConfig), privacy: .public)")

        guard Endpoint(from: tunnelConfig.endpoint) != nil else {
            let error = NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint format: \(tunnelConfig.endpoint)"])
            logger.error("Invalid endpoint format: \(tunnelConfig.endpoint, privacy: .public)")
            completionHandler(error)
            return
        }

        let tunnelConfiguration = TunnelConfiguration(fromStartData: tunnelConfig)
        let networkSettings = tunnelConfiguration.asNetworkSettings()

        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                logger.warning("Set tunnel network settings returned an error \(error, privacy: .public)")
                completionHandler(error)
                return
            }

            do {
                try self.adapter.start(tunnelConfiguration: tunnelConfiguration)
            } catch {
                logger.error("Failed to start adapter with error: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
                return
            }

            logger.log("Tunnel started successfully")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        self.adapter.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logger.debug("\(#function)")
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        logger.debug("\(#function)")
        completionHandler()
    }

    override func wake() {
        logger.debug("\(#function)")
    }

    // MARK: - Helpers

    private func extractTunnelConfiguration() -> TunnelStartData? {
        guard let providerConfig = (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration as? [String: Any] else {
            return nil
        }
        return try? TunnelStartData.from(dictionary: providerConfig)
    }
}
