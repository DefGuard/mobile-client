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
    private var appStateObservers: [NSObjectProtocol] = []
    private var configurationObserver: NSObjectProtocol?
    private var providerManager: NETunnelProviderManager?

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

        instance.setupProviderManager()
        instance.setupAppObservers()
        instance.setupVPNObservers()
    }

    private func setupProviderManager() {
        getSystemProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found")
                completion(nil)
                return
            }
            self.providerManager = providerManager
        }
    }


    /// Loads the active tunnel data from the system configuration.
    private func getActiveTunnelData(
        completion: @escaping (ActiveTunnelData?) -> Void
    ) {
        guard let providerManager = self.providerManager else {
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

    private func setupAppObservers() {
        let appActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: OperationQueue.main) { _ in
                print("App became active, updating VPN status")
                self.handleVPNStatusChange()
            }
        self.appStateObservers.append(appActiveObserver)
    }

    /// Sets up observers for VPN connection status changes.
    private func setupVPNObservers() {
        if self.connectionObserver != nil {
            print("VPN observers already set up, removing it first")
            removeVPNObservers()
        }
        guard let providerManager = self.providerManager else {
            print("No provider manager found, cannot set up VPN observers")
            return
        }
        self.connectionObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: providerManager.connection, queue: OperationQueue.main, using: { notification in
            self.handleVPNStatusChange()
        })
        self.configurationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NEVPNConfigurationChange,
            object: nil, queue: OperationQueue.main, using: { notification in
                self.handleVPNConfigurationChange()
            })
    }

    private func handleVPNConfigurationChange() {
        print("VPN configuration changed, updating provider manager")
        getSystemProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found after configuration change")
                return
            }
            self.providerManager = providerManager
            self.handleVPNStatusChange()
        }
    }

    private func removeAppObservers() {
        for observer in appStateObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        appStateObservers.removeAll()
    }

    private func removeVPNObservers() {
        if let observer = connectionObserver {
            NotificationCenter.default.removeObserver(observer)
            connectionObserver = nil
        }
        if let observer = configurationObserver {
            NotificationCenter.default.removeObserver(observer)
            configurationObserver = nil
        }
    }

    deinit {
        removeVPNObservers()
        removeAppObservers()
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
        guard let providerManager = self.providerManager else {
            print("No VPN manager found")
            completion(nil)
            return
        }
        let connection = providerManager.connection
        completion(connection.status)
    }

    /// Loads the provider manager from the system preferences.
    private func getSystemProviderManager(
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

    /// Updates the UI status of the VPN connection. Used when the status changes asynchronously.
    private func handleVPNStatusChange() {
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
                    self.activeTunnelData = activeTunnelData
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
                            return
                        }
                        self.activeTunnelData = activeTunnelData
                        self.emitEvent(
                            event: WireguardEvent.tunnelUp,
                            data: dataString
                        )
                    }
                }
                self.setupVPNObservers()
            case .disconnected, .invalid:
                print("Detected that the VPN has disconnected or became invalid, emitting event.")
                self.activeTunnelData = nil
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
        getSystemProviderManager { manager in
            let appId = Bundle.main.bundleIdentifier ?? "net.defguard.mobile"
            let providerManager = manager ?? NETunnelProviderManager()
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
        let timeoutInterval = 10.0
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
            self.getSystemProviderManager { providerManager in
                if let providerManager = providerManager {
                    self.providerManager = providerManager
                    self.startVPNTunnel(with: providerManager, config: config, result: result)
                } else {
                    print("Failed to load provider manager")
                    result(
                        FlutterError(
                            code: "SAVE_ERROR", message: "Failed to load VPN provider manager",
                            details: "No provider manager found"))
                    return
                }
            }
        }
    }

    private func closeTunnel(result: @escaping FlutterResult) {
        print("Stopping tunnel")
        guard let providerManager = self.providerManager else {
            print("No VPN manager found to stop")
            result(
                FlutterError(code: "NO_MANAGER", message: "No VPN manager found", details: nil))
            return
        }
        let connection = providerManager.connection
        if connection.status == .connected || connection.status == .connecting {
            self.removeVPNObservers()
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
                    self.handleVPNStatusChange()
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
                    self.handleVPNStatusChange()
                    print("VPN tunnel started successfully")
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
