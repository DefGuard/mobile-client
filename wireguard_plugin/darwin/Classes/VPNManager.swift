//
//  VPNManager.swift
//  Pods
//
//  Created by Aleksander on 16/07/2025.
//

import NetworkExtension

public protocol VPNManagement {
    func loadProviderManager(
        completion: @escaping (NETunnelProviderManager?) -> Void
    )
    func saveProviderManager(
        _ manager: NETunnelProviderManager,
        completion: @escaping (Error?) -> Void
    )
    func getConnectionStatus() -> NEVPNStatus?
    func startTunnel() throws
    func stopTunnel() throws
    func getProviderManager() -> NETunnelProviderManager?
    func handleVPNConfigurationChange()
}

public class VPNManager: VPNManagement {
    static let shared = VPNManager()

    init() {
    }

    var providerManager: NETunnelProviderManager?

    /// Loads the provider manager from the system preferences.
    public func loadProviderManager(
        completion: @escaping (NETunnelProviderManager?) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            print("loadAllFromPreferences \(managers?.count ?? 0)")
            guard error == nil else {
                print("Error loading managers: \(String(describing: error))")
                self.providerManager = nil
                completion(nil)
                return
            }
            guard let providerManager = managers?.first else {
                print("No VPN manager found")
                self.providerManager = nil
                completion(nil)
                return
            }

            self.providerManager = providerManager
            print(
                "Loaded provider manager: \(String(describing: providerManager.localizedDescription))"
            )
            completion(providerManager)
        }
    }

    public func saveProviderManager(
        _ manager: NETunnelProviderManager,
        completion: @escaping (Error?) -> Void
    ) {
        manager.saveToPreferences { error in
            if let error = error {
                print("Failed to save provider manager: \(error)")
                completion(error)
            } else {
                print("Provider manager saved successfully, reloading it")
                self.loadProviderManager { providerManager in
                    self.providerManager = providerManager
                    print("The provider manager has been reloaded.")
                    completion(nil)
                }
            }

        }
    }

    public func getConnectionStatus() -> NEVPNStatus? {
        guard let providerManager = providerManager else {
            print("Provider manager is not set")
            return nil
        }

        return providerManager.connection.status
    }

    public func getProviderManager() -> NETunnelProviderManager? {
        return providerManager
    }

    public func handleVPNConfigurationChange() {
        print("VPN configuration changed, updating provider manager")
        self.loadProviderManager { providerManager in
            guard let providerManager = providerManager else {
                print("No VPN manager found after configuration change")
                return
            }
            self.providerManager = providerManager
        }
    }

    public func startTunnel() throws {
        guard let providerManager = providerManager else {
            throw NSError(
                domain: "VPNManagerError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Provider manager is not set"
                ]
            )
        }

        try providerManager.connection.startVPNTunnel()
        print("VPN tunnel started successfully")
    }

    public func stopTunnel() throws {
        guard let providerManager = providerManager else {
            throw NSError(
                domain: "VPNManagerError",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Provider manager is not set"
                ]
            )
        }

        providerManager.connection.stopVPNTunnel()
        print("VPN tunnel stopped successfully")
    }
}
