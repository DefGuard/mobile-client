//
//  MockVPNManager.swift
//  Runner
//
//  Created by Aleksander on 17/07/2025.
//

import NetworkExtension
import wireguard_plugin

public enum MockEvents {
    case connected
    case disconnected
    case configurationChanged
}

class MockVPNManager: VPNManagement {
    var providerManager: NETunnelProviderManager?
    var connectionStatus: NEVPNStatus = .disconnected
    var events: [MockEvents] = []

    func loadProviderManager(
        completion: @escaping (NETunnelProviderManager?) -> Void
    ) {
        completion(providerManager)
    }

    func saveProviderManager(
        _ manager: NETunnelProviderManager,
        completion: @escaping (Error?) -> Void
    ) {
        providerManager = manager
        completion(nil)
    }

    func getConnectionStatus() -> NEVPNStatus? {
        return connectionStatus
    }

    func startTunnel() throws {
        guard providerManager != nil else {
            throw NSError(
                domain: "MockVPNManagerError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Provider manager is not set"
                ]
            )
        }
        self.connectionStatus = .connected
        events.append(.connected)
    }

    func stopTunnel() throws {
        guard providerManager != nil else {
            throw NSError(
                domain: "MockVPNManagerError",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Provider manager is not set"
                ]
            )
        }
        self.connectionStatus = .disconnected
        events.append(.disconnected)
    }

    func getProviderManager() -> NETunnelProviderManager? {
        return providerManager
    }

    func handleVPNConfigurationChange() {
        events.append(.configurationChanged)
    }

    func clearEvents() {
        events.removeAll()
    }

    func vpnEventsEqual(_ otherEvents: [MockEvents], orderMatters: Bool = true)
        -> Bool
    {
        if orderMatters {
            return events == otherEvents
        } else {
            return Set(events) == Set(otherEvents)
        }
    }
}
