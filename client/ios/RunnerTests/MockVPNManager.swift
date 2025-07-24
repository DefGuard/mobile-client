import NetworkExtension
import wireguard_plugin

public enum MockEvents {
    case connected
    case disconnected
    case configurationChanged
}

class MockVPNManager: VPNManagement {
    public private(set) var providerManager: NETunnelProviderManager?
    public var connectionStatus: NEVPNStatus = .disconnected
    var events: [MockEvents] = []

    func loadProviderManager(completion: @escaping (NETunnelProviderManager?) -> Void) {
        completion(providerManager)
    }

    func saveProviderManager(
        _ manager: NETunnelProviderManager,
        completion: @escaping (Error?) -> Void
    ) {
        providerManager = manager
        completion(nil)
    }

    func startTunnel() throws {
        guard providerManager != nil else {
            throw VPNManagerError.providerManagerNotSet
        }
        connectionStatus = .connected
        events.append(.connected)
    }

    func stopTunnel() throws {
        guard providerManager != nil else {
            throw VPNManagerError.providerManagerNotSet
        }
        connectionStatus = .disconnected
        events.append(.disconnected)
    }

    func handleVPNConfigurationChange() {
        events.append(.configurationChanged)
    }

    func clearEvents() {
        events.removeAll()
    }

    func vpnEventsEqual(_ otherEvents: [MockEvents], orderMatters: Bool = true) -> Bool {
        return if orderMatters {
            events == otherEvents
        } else {
            Set(events) == Set(otherEvents)
        }
    }
}
