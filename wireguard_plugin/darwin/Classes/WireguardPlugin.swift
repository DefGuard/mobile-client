import NetworkExtension

#if os(macOS)
    import FlutterMacOS
    import Cocoa
#elseif os(iOS)
    import Flutter
#endif

public class WireguardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "net.defguard.wireguard_plugin/channel",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "net.defguard.wireguard_plugin/event",
            binaryMessenger: registrar.messenger()
        )

        let instance = WireguardPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "requestPermissions":
            result(true)

        case "startTunnel":
            guard
                let args = call.arguments as? String,
                let data = args.data(using: .utf8)
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Invalid or missing tunnel config",
                        details: nil
                    )
                )
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            guard let config = try? decoder.decode(TunnelStartData.self, from: data) else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Invalid or missing tunnel config",
                        details: nil
                    )
                )
                return
            }

            startTunnel(config: config, result: result)

        case "closeTunnel":
            closeTunnel(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startTunnel(
        config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        print("Starting tunnel with config: \(config)")
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            print("loadAllFromPreferences \(managers?.count ?? 0)")
            guard error == nil else {
                print("Error loading managers: \(String(describing: error))")
                result(
                    FlutterError(
                        code: "LOAD_ERROR", message: "Failed to load VPN managers",
                        details: error?.localizedDescription))
                return
            }

            let appId = Bundle.main.bundleIdentifier ?? "net.defguard.mobile"
            let providerManager = managers?.first ?? NETunnelProviderManager()
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = "\(appId).VPNExtension"
            tunnelProtocol.serverAddress = config.endpoint
            tunnelProtocol.providerConfiguration = toDictionary(config)
            providerManager.protocolConfiguration = tunnelProtocol
            providerManager.localizedDescription = config.locationName
            providerManager.isEnabled = true

            let connection = providerManager.connection
            if connection.status == .connected || connection.status == .connecting {
                connection.stopVPNTunnel()
                print("Stopped running VPN tunnel to update config")
                self.waitForTunnelToDisconnect(connection: connection) {
                    self.saveAndStartTunnel(
                        providerManager: providerManager, config: config, result: result)
                }
            } else {
                self.saveAndStartTunnel(
                    providerManager: providerManager, config: config, result: result)
            }
        }
    }

    private func waitForTunnelToDisconnect(
        connection: NEVPNConnection, completion: @escaping () -> Void
    ) {
        let checkInterval = 0.2
        func check() {
            if connection.status == .disconnected || connection.status == .invalid {
                completion()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
                    check()
                }
            }
        }
        check()
    }

    private func saveAndStartTunnel(
        providerManager: NETunnelProviderManager, config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        providerManager.saveToPreferences { saveError in
            if let saveError = saveError {
                print("Failed to save preferences: \(saveError)")
                result(
                    FlutterError(
                        code: "SAVE_ERROR", message: "Failed to save VPN preferences",
                        details: saveError.localizedDescription))
                return
            }
            providerManager.loadFromPreferences { loadError in
                if let loadError = loadError {
                    print("Failed to load preferences: \(loadError)")
                    result(
                        FlutterError(
                            code: "LOAD_ERROR", message: "Failed to reload VPN preferences",
                            details: loadError.localizedDescription))
                    return
                }
                self.startVPNTunnel(with: providerManager, config: config, result: result)
            }
        }
    }

    private func closeTunnel(result: @escaping FlutterResult) {
        print("Stopping tunnel")
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            print("loadAllFromPreferences \(managers?.count ?? 0)")
            guard error == nil else {
                print("Error loading managers: \(String(describing: error))")
                result(
                    FlutterError(
                        code: "LOAD_ERROR", message: "Failed to load VPN managers",
                        details: error?.localizedDescription))
                return
            }

            guard let providerManager = managers?.first else {
                print("No VPN manager found to stop")
                result(
                    FlutterError(code: "NO_MANAGER", message: "No VPN manager found", details: nil))
                return
            }

            let connection = providerManager.connection
            if connection.status == .connected || connection.status == .connecting {
                connection.stopVPNTunnel()
                print("VPN tunnel stopped")
                self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
                result(nil)
            } else {
                print("VPN tunnel is not running")
                result(nil)
            }
        }

        emitEvent(event: WireguardEvent.tunnelDown, data: nil)

        result(nil)
    }

    private func emitEvent(event: WireguardEvent, data: String?) {
        guard let eventSink = eventSink else { return }

        let event: [String: Any?] = [
            "event": event.rawValue,
            "data": data,
        ]

        eventSink(event)
    }

    private func startVPNTunnel(
        with providerManager: NETunnelProviderManager, config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        do {
            try providerManager.connection.startVPNTunnel()
            print("VPN tunnel started successfully")
            let activeTunnelData = ActiveTunnelData(fromConfig: config)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase

            guard let dataString = try? encoder.encode(activeTunnelData),
                let dataString = String(data: dataString, encoding: .utf8)
            else {
                result(
                    FlutterError(
                        code: "ENCODING_ERROR", message: "Failed to encode tunnel data",
                        details: nil))
                return
            }

            emitEvent(event: WireguardEvent.tunnelUp, data: dataString)
            result(nil)

        } catch {
            print("Failed to start VPN: \(error)")
            result(
                FlutterError(
                    code: "START_ERROR", message: "Failed to start VPN tunnel",
                    details: error.localizedDescription))
        }
    }
}
