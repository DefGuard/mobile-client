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
        networkSettings.tunnelOverheadBytes = 80
        let dnsServers = interface.dns.map { ip in String(describing: ip) }
        let dnsSettings = NEDNSSettings(servers: dnsServers)
        dnsSettings.searchDomains = interface.dnsSearch
        networkSettings.dnsSettings = dnsSettings

        return networkSettings
    }

    /// Helper function allowing to parse comma-separated string of addresses.
    private func parseAddresses(fromString string: String) -> [IpAddrMask] {
        var addresses: [IpAddrMask] = []

        for addr in string.split(separator: ",").map({ String($0.trimmingCharacters(in: .whitespaces)) }) {
            if let addr_mask = IpAddrMask(fromString: addr) {
                addresses.append(addr_mask)
            }
        }

        return addresses
    }

    init(fromStartData startData: TunnelStartData) {
        name = startData.locationName
        interface = InterfaceConfiguration(privateKey: startData.privateKey)
        let peer = Peer(publicKey: startData.publicKey)
        peers = [peer]

        interface.addresses = self.parseAddresses(fromString: startData.address)

        // DNS settings
        let dnsRecords = startData.dns?.split(separator: ",").map {
            String($0.trimmingCharacters(in: .whitespaces))
        } ?? []
        if !dnsRecords.isEmpty {
            for record in dnsRecords {
                if IPv4Address(record) != nil || IPv6Address(record) != nil {
                    interface.dns.append(record)
                } else {
                    interface.dnsSearch.append(record)
                }
            }
        }

        // Peer settings
        peer.preSharedKey = startData.presharedKey
        peer.endpoint = Endpoint(from: startData.endpoint)
        peer.persistentKeepAlive = UInt16(startData.keepalive)
        peer.allowedIPs = switch startData.traffic {
            case .All:
                [
                    IpAddrMask(address: IPv4Address.any, cidr: 0),
                    IpAddrMask(address: IPv6Address.any, cidr: 0)
                ]
            case .Predefined:
                self.parseAddresses(fromString: startData.allowedIps)
        }
    }
}

//extension TunnelConfiguration: Equatable {
//    public static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool {
//        return lhs.name == rhs.name &&
//            lhs.interface == rhs.interface &&
//            Set(lhs.peers) == Set(rhs.peers)
//    }
//}
