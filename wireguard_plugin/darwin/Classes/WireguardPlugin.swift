import NetworkExtension

#if os(macOS)
    import FlutterMacOS
    import Cocoa
#elseif os(iOS)
    import Flutter
#endif



public class WireguardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var activeTunnelData: ActiveTunnelData?
    private var connectionObserver: NSObjectProtocol?

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
    
    
    /// Loads the active tunnel data from the system configuration.
    private func getActiveTunnelData(
        completion: @escaping (ActiveTunnelData?) -> Void
    ) {
        getProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found")
                return
            }
            
            if let config = providerManager.protocolConfiguration as? NETunnelProviderProtocol,
               let configDict = config.providerConfiguration,
               let activeTunnelData = try? ActiveTunnelData.from(dictionary: configDict) {
                completion(activeTunnelData)
            } else {
                print("No active tunnel data available")
                completion(nil)
            }
        }
    }

    
    private func setupObservers(connection: NEVPNConnection) {
        self.connectionObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: connection, queue: OperationQueue.main, using: { notification in
            self.updateStatus()
        })
    }

    private func removeObservers() {
        if let observer = connectionObserver {
            NotificationCenter.default.removeObserver(observer)
            connectionObserver = nil
        }
    }

    deinit {
        removeObservers()
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
    
    private func checkStatus(
        completion: @escaping (NEVPNStatus?) -> Void
    ) {
        getProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found")
                completion(nil)
                return
            }
            
            let connection = providerManager.connection
            completion(connection.status)
        }
    }
    
    private func getProviderManager(
        completion: @escaping (NETunnelProviderManager?) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            print("loadAllFromPreferences \(managers?.count ?? 0)")
            guard error == nil else {
                print("Error loading managers: \(String(describing: error))")
                completion(nil)
                return
            }
            guard let providerManager = managers?.first else {
                print("No VPN manager found")
                completion(nil)
                return
            }
            
            completion(providerManager)
        }
    }
    
    private func updateStatus() {
        checkStatus { vpnStatus in
            guard let vpnStatus = vpnStatus else {
                print("Failed to get VPN status, returning nil")
                return
            }
            
            switch vpnStatus {
            case .connected:
                print("Detected that the VPN has connected, emitting event.")
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                if let activeTunnelData = self.activeTunnelData {
                    guard let data = try? encoder.encode(activeTunnelData),
                          let dataString = String(data: data, encoding: .utf8) else {
                        print("Failed to encode active tunnel data")
                        return
                    }
                    self.emitEvent(event: WireguardEvent.tunnelUp, data: dataString)
                } else {
                    self.getActiveTunnelData { activeTunnelData in
                        guard let activeTunnelData = activeTunnelData else {
                            print("No active tunnel data available")
                            self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
                            return
                        }
                        
                        guard let data = try? encoder.encode(activeTunnelData),
                              let dataString = String(data: data, encoding: .utf8) else {
                            print("Failed to encode active tunnel data")
                            self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
                            return
                        }
                        
                        self.emitEvent(
                            event: WireguardEvent.tunnelUp,
                            data: dataString
                        )
                    }
                    
                }
            case .disconnected, .invalid:
                print("Detected that the VPN has disconnected or became invalid, emitting event.")
                self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
            case .connecting:
                print("Detected that the VPN is connecting, emitting event.")
                self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
            case .disconnecting:
                print("Detected that the VPN is VPN is disconnecting, emitting event.")
                self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
            case .reasserting:
                print("Detected that the VPN is reasserting, emitting event.")
                self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
            @unknown default:
                print("Detected unknown VPN status: \(vpnStatus), not emitting any event")
            }
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
            guard let configDict = try? config.toDictionary() else {
                result(
                    FlutterError(
                        code: "CONFIG_ERROR",
                        message: "Failed to convert config to dictionary",
                        details: nil
                    )
                )
                return
            }
            tunnelProtocol.providerConfiguration = configDict
            providerManager.protocolConfiguration = tunnelProtocol
            providerManager.localizedDescription = config.locationName
            providerManager.isEnabled = true

            let connection = providerManager.connection
            if connection.status == .connected || connection.status == .connecting {
                connection.stopVPNTunnel()
                print("Stopped running VPN tunnel to update config")
                self.waitForTunnelStatus(connection: connection, desiredStatuses: [.disconnected, .invalid]) { status in
                    if let status = status {
                        print("Timeout waiting for tunnel to disconnect")
                        result(
                            FlutterError(
                                code: "TIMEOUT_ERROR",
                                message: "Timeout waiting for tunnel to disconnect",
                                details: "Current status: \(status.rawValue)"
                            )
                        )
                        return
                    }
                    self.saveAndStartTunnel(
                        providerManager: providerManager, config: config, result: result)
                }
            } else {
                self.saveAndStartTunnel(
                    providerManager: providerManager, config: config, result: result)
            }
        }
    }

    /// Waits for the VPN connection to reach one of the desired statuses.
    /// If it does not reach the desired status within the timeout,
    /// it returns the current status.
    private func waitForTunnelStatus(
        connection: NEVPNConnection,
        desiredStatuses: [NEVPNStatus],
        completion: @escaping (NEVPNStatus?) -> Void
    ) {
        let checkInterval = 0.2
        let timeoutInterval = 3.0
        var elapsedTime = 0.0
        func check() {
            print("Checking VPN status: \(connection.status.rawValue)")
            if desiredStatuses.contains(connection.status) {
                print("Desired VPN status reached: \(connection.status.rawValue)")
                completion(nil)
            } else {
                elapsedTime += checkInterval
                if elapsedTime >= timeoutInterval {
                    completion(connection.status)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
                        check()
                    }
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
        getProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found to stop")
                result(
                    FlutterError(code: "NO_MANAGER", message: "No VPN manager found", details: nil))
                return
            }
            let connection = providerManager.connection
            if connection.status == .connected || connection.status == .connecting {
                self.removeObservers()
                connection.stopVPNTunnel()
                self.waitForTunnelStatus(
                    connection: connection,
                    desiredStatuses: [.disconnected, .invalid]) { status in
                        if let status = status {
                            print("Timeout waiting for tunnel to disconnect: \(status.rawValue)")
                            result(
                                FlutterError(
                                    code: "TIMEOUT_ERROR",
                                    message: "Timeout waiting for tunnel to disconnect",
                                    details: "Current status: \(status.rawValue)"
                                )
                            )
                            return
                        }
                        self.activeTunnelData = nil
                        self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
                        print("VPN tunnel stopped")
                        result(nil)
                }
            } else {
                print("VPN tunnel is not running")
                // Emit event just to update the UI if its broken
                self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
                result(nil)
            }

        }
    }

    private func emitEvent(event: WireguardEvent, data: String?) {
        print("Emitting event: \(event.rawValue), data: \(String(describing: data))")
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
            self.waitForTunnelStatus(
                connection: providerManager.connection,
                desiredStatuses: [.connected]) { status in
                    if let status = status {
                        print("Timeout waiting for tunnel to connect.")
                        result(
                            FlutterError(
                                code: "TIMEOUT_ERROR",
                                message: "Timeout waiting for tunnel to connect",
                                details: "Current status: \(status.rawValue)"
                                )
                            )
                        return
                    }
                    print("VPN tunnel started successfully")
                    let activeTunnelData = ActiveTunnelData(fromConfig: config)
                    self.activeTunnelData = activeTunnelData
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    guard let data = try? encoder.encode(activeTunnelData),
                          let dataString = String(data: data, encoding: .utf8) else {
                        print("Failed to encode active tunnel data")
                        result(
                            FlutterError(
                                code: "START_ERROR", message: "Failed to start VPN tunnel",
                                details: "Failed to encode active tunnel data"
                        ))
                        return
                    }
                    self.emitEvent(event: WireguardEvent.tunnelUp, data: dataString)
                    self.setupObservers(connection: providerManager.connection)
                    result(nil)
                }
        } catch {
            print("Failed to start VPN: \(error)")
            result(
                FlutterError(
                    code: "START_ERROR", message: "Failed to start VPN tunnel",
                    details: error.localizedDescription))
        }
    }
}
