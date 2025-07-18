import NetworkExtension

#if os(macOS)
    import FlutterMacOS
    import Cocoa
#elseif os(iOS)
    import Flutter
#endif

// The timeout for waiting for the tunnel status to change (e.g. when connecting or disconnecting).
let tunnelStatusTimeout: TimeInterval = 10.0

public class WireguardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var activeTunnelData: ActiveTunnelData?
    private var connectionObserver: NSObjectProtocol?
    private var appStateObservers: [NSObjectProtocol] = []
    private var configurationObserver: NSObjectProtocol?
    private var vpnManager: VPNManagement

    public init(vpnManager: VPNManagement? = nil) {
        if let vpnManager = vpnManager {
            print("Using provided VPN manager")
            self.vpnManager = vpnManager
        } else {
            print("Creating new VPN manager instance")
            self.vpnManager = VPNManager.shared
        }
        super.init()
    }

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
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

        instance.setupVPNManager()
        instance.setupAppObservers()
    }

    /// Loads the active tunnel data from the system configuration.
    private func getActiveTunnelData(
        completion: @escaping (ActiveTunnelData?) -> Void
    ) {
        guard let providerManager = self.vpnManager.getProviderManager() else {
            print("No VPN manager found")
            return
        }

        if let config = providerManager.protocolConfiguration
            as? NETunnelProviderProtocol,
            let configDict = config.providerConfiguration,
            let activeTunnelData = try? ActiveTunnelData.from(
                dictionary: configDict
            )
        {
            completion(activeTunnelData)
        } else {
            print("No active tunnel data available")
            completion(nil)
        }
    }

    /// Loads the possibly already existing VPN manager and sets up observers for VPN connection status changes if its present.
    /// This is to ensure that the VPN status is observed and updated correctly when the app starts.
    private func setupVPNManager() {
        self.vpnManager.loadProviderManager { manager in
            guard let _ = manager else {
                print("No provider manager found, the VPN status won't be observed until the VPN is started.")
                return
            }
            print("VPN manager loaded successfully, the VPN status will be observed and updated.")
            self.handleVPNStatusChange()
            self.setupVPNObservers()
        }
    }

    private func setupAppObservers() {
        let appActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
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
        guard let providerManager = self.vpnManager.getProviderManager() else {
            print("No provider manager found, cannot set up VPN observers")
            return
        }
        self.connectionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NEVPNStatusDidChange,
            object: providerManager.connection,
            queue: OperationQueue.main,
            using: { notification in
                self.handleVPNStatusChange()
            }
        )
        self.configurationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NEVPNConfigurationChange,
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                self.vpnManager.handleVPNConfigurationChange()
                self.handleVPNStatusChange()
            }
        )
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
                    VPNError.invalidArguments(
                        "Invalid or missing tunnel config: \(call.arguments ?? "nil")"
                    ).flutterError
                )
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let config: TunnelStartData
            do {
                config = try decoder.decode(
                    TunnelStartData.self,
                    from: data
                )
            } catch {
                print(
                    "Failed to decode tunnel config: \(error.localizedDescription)"
                )
                result(
                    VPNError.configurationError(
                        error
                    ).flutterError
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

    /// Updates the UI status of the VPN connection. Used when the status changes asynchronously.
    private func handleVPNStatusChange() {
        guard let vpnStatus = self.vpnManager.getConnectionStatus() else {
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
                    let dataString = String(data: data, encoding: .utf8)
                else {
                    print("Failed to encode active tunnel data")
                    return
                }
                self.activeTunnelData = activeTunnelData
                self.emitEvent(
                    event: WireguardEvent.tunnelUp,
                    data: dataString
                )
            } else {
                self.getActiveTunnelData { activeTunnelData in
                    guard let activeTunnelData = activeTunnelData else {
                        print("No active tunnel data available")
                        self.emitEvent(
                            event: WireguardEvent.tunnelDown,
                            data: nil
                        )
                        return
                    }
                    guard let data = try? encoder.encode(activeTunnelData),
                        let dataString = String(data: data, encoding: .utf8)
                    else {
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
            print(
                "Detected that the VPN has disconnected or became invalid, emitting event."
            )
            self.activeTunnelData = nil
            self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
        case .connecting:
            print("Detected that the VPN is connecting, emitting event.")
            self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
        case .disconnecting:
            print(
                "Detected that the VPN is VPN is disconnecting, emitting event."
            )
            self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
        case .reasserting:
            print("Detected that the VPN is reasserting, emitting event.")
            self.emitEvent(event: WireguardEvent.tunnelWaiting, data: nil)
        @unknown default:
            print(
                "Detected unknown VPN status: \(vpnStatus), not emitting any event"
            )
        }
    }

    private func startTunnel(
        config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        print("Starting tunnel with config: \(config)")

        vpnManager.loadProviderManager { manager in
            let appId = Bundle.main.bundleIdentifier ?? "net.defguard.mobile"
            let providerManager = manager ?? NETunnelProviderManager()
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = "\(appId).VPNExtension"
            tunnelProtocol.serverAddress = config.endpoint
            let configDict: [String: Any]
            do {
                configDict = try config.toDictionary()
            } catch {
                print(
                    "Failed to convert config to dictionary: \(error.localizedDescription)"
                )
                result(
                    VPNError.configurationError(error).flutterError
                )
                return
            }
            tunnelProtocol.providerConfiguration = configDict
            providerManager.protocolConfiguration = tunnelProtocol
            providerManager.localizedDescription = config.locationName
            providerManager.isEnabled = true

            let status = self.vpnManager.getConnectionStatus()
            if let status = status {
                if status == .connected
                    || status == .connecting
                {
                    do {
                        try self.vpnManager.stopTunnel()
                    } catch {
                        print("Failed to stop VPN tunnel: \(error)")
                        result(
                            VPNError.stopError(
                                error
                            ).flutterError
                        )
                        return
                    }
                    print("Stopped running VPN tunnel to update config")
                    self.waitForTunnelStatus(
                        desiredStatuses: [.disconnected, .invalid]
                    ) { status in
                        if let status = status {
                            print("Timeout waiting for tunnel to disconnect")
                            result(
                                VPNError.timeoutError(
                                    "The tunnel disconnection has failed to complete in a specified amount of time (\(tunnelStatusTimeout) seconds). Please check your configuration and try again. Current status: \(status.rawValue)"
                                ).flutterError
                            )
                            return
                        }
                        self.saveAndStartTunnel(
                            providerManager: providerManager,
                            config: config,
                            result: result
                        )
                        return
                    }
                }
            }
            self.saveAndStartTunnel(
                providerManager: providerManager,
                config: config,
                result: result
            )
        }
    }

    /// Waits for the VPN connection to reach one of the desired statuses.
    /// If it does not reach the desired status within the timeout,
    /// it returns the current status.
    private func waitForTunnelStatus(
        desiredStatuses: [NEVPNStatus],
        completion: @escaping (NEVPNStatus?) -> Void
    ) {
        let checkInterval = 0.2
        var elapsedTime = 0.0
        func check() {
            let status = self.vpnManager.getConnectionStatus()
            guard let status = status else {
                print("No VPN connection status available")
                completion(nil)
                return
            }
            print("Checking VPN status: \(status.rawValue)")
            if desiredStatuses.contains(status) {
                print(
                    "Desired VPN status reached: \(status.rawValue)"
                )
                completion(nil)
            } else {
                elapsedTime += checkInterval
                if elapsedTime >= tunnelStatusTimeout {
                    completion(status)
                } else {
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + checkInterval
                    ) {
                        check()
                    }
                }
            }
        }
        check()
    }

    private func saveAndStartTunnel(
        providerManager: NETunnelProviderManager,
        config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        self.vpnManager.saveProviderManager(providerManager) { saveError in
            if let saveError = saveError {
                print("Failed to save preferences: \(saveError)")
                result(
                    VPNError.saveError(
                        saveError
                    ).flutterError
                )
                return
            }
            self.startVPNTunnel(
                config: config,
                result: result
            )
        }
    }

    private func closeTunnel(result: @escaping FlutterResult) {
        print("Stopping tunnel")

        guard let status = self.vpnManager.getConnectionStatus() else {
            print("No VPN connection status available")
            result(
                VPNError.noManager(
                    "No VPN connection status available. The tunnel may not be running."
                ).flutterError
            )
            self.emitEvent(event: WireguardEvent.tunnelDown, data: nil)
            return
        }

        if status == .connected || status == .connecting {
            self.removeVPNObservers()
            do {
                try self.vpnManager.stopTunnel()
            } catch {
                print("Failed to stop VPN tunnel: \(error)")
                result(
                    VPNError.stopError(
                        error
                    ).flutterError
                )
                return
            }

            self.waitForTunnelStatus(
                desiredStatuses: [.disconnected, .invalid]
            ) { status in
                if let status = status {
                    print(
                        "Timeout waiting for tunnel to disconnect: \(status.rawValue)"
                    )
                    result(
                        VPNError.timeoutError(
                            "The tunnel disconnection has failed to complete in a specified amount of time (\(tunnelStatusTimeout) seconds). Please check your configuration and try again."
                        ).flutterError
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
        print(
            "Emitting event: \(event.rawValue), data: \(String(describing: data))"
        )
        guard let eventSink = eventSink else { return }
        let event: [String: Any?] = [
            "event": event.rawValue,
            "data": data,
        ]
        eventSink(event)
    }

    private func startVPNTunnel(
        config: TunnelStartData,
        result: @escaping FlutterResult
    ) {
        do {
            try vpnManager.startTunnel()
            // This is done because the frontend expects a blocking action to display a loading indicator.
            self.waitForTunnelStatus(
                desiredStatuses: [.connected]
            ) { status in
                if status != nil {
                    print("Timeout waiting for tunnel to connect.")
                    result(
                        VPNError.timeoutError(
                            "The tunnel connection has failed to be established in a specified amount of time. Please check your configuration and try again."
                        ).flutterError
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
                VPNError.startError(
                    error,
                ).flutterError
            )
        }
    }
}
