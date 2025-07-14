import Foundation
import NetworkExtension

final class TunnelConfiguration: Codable {
    var name: String
    var interface: InterfaceConfiguration
    var peers: [Peer]

    init(name: String, interface: InterfaceConfiguration, peers: [Peer]) {
        self.interface = interface
        self.peers = peers
        self.name = name

        let peerPublicKeysArray = peers.map { $0.publicKey }
        let peerPublicKeysSet = Set<String>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            fatalError("Two or more peers cannot have the same public key")
        }
    }

    // Only encode these properties.
    enum CodingKeys: String, CodingKey {
        case name
        case interface
        case peers
    }

    func asNetworkSettings() -> NEPacketTunnelNetworkSettings {
        // Keep 127.0.0.1 as remote address for WireGuard.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        // IPv4 addresses
        let addrs_v4 = interface.addresses.filter { $0.address is IPv4Address }
            .map { String(describing: $0.address) }
        let masks_v4 = interface.addresses.filter { $0.address is IPv4Address }
            .map { String(describing: $0.mask()) }
        let ipv4Settings = NEIPv4Settings(addresses: addrs_v4, subnetMasks: masks_v4)
        ipv4Settings.includedRoutes = peers[0].allowedIPs.filter { $0.address is IPv4Address }.map {
            NEIPv4Route(destinationAddress: "\($0.address)", subnetMask: "\($0.mask())")
        }
        networkSettings.ipv4Settings = ipv4Settings

        // IPv6 addresses
        let addrs_v6 = interface.addresses.filter { $0.address is IPv6Address }
            .map { String(describing: $0.address) }
        let masks_v6 = interface.addresses.filter { $0.address is IPv6Address }
            .map { NSNumber(value: $0.cidr) }
        let ipv6Settings = NEIPv6Settings(addresses: addrs_v6, networkPrefixLengths: masks_v6)
        ipv6Settings.includedRoutes = peers[0].allowedIPs.filter { $0.address is IPv6Address }.map {
            NEIPv6Route(destinationAddress: "\($0.address)",
                        networkPrefixLength: NSNumber(value: $0.cidr))
        }
        networkSettings.ipv6Settings = ipv6Settings

        networkSettings.mtu = interface.mtu as NSNumber?
        let dnsServers = interface.dns.map { ip in String(describing: ip) }
        let dnsSettings = NEDNSSettings(servers: dnsServers)
        dnsSettings.searchDomains = interface.dnsSearch
        networkSettings.dnsSettings = dnsSettings

        return networkSettings
    }
}

//extension TunnelConfiguration: Equatable {
//    public static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool {
//        return lhs.name == rhs.name &&
//            lhs.interface == rhs.interface &&
//            Set(lhs.peers) == Set(rhs.peers)
//    }
//}
