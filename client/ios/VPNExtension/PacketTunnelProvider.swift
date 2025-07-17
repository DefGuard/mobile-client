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

    private var logger = Logger(subsystem: "net.defguard.mobile.Client", category: "VPNExtension")

    private lazy var adapter: Adapter = {
        return Adapter(with: self)
    }()

    private struct DestinationAddrs {
        // (Addr, Mask) tuples
        var ipv4Addrs: [(String, String)]
        var ipv6Addrs: [(String, Int)]

        static func cidrToMask(_ cidr: Int) -> String {
            let mask: UInt32 = cidr == 0 ? 0 : ~UInt32(0) << (32 - cidr)
            return (0..<4).map { String((mask >> (8 * (3 - $0))) & 0xFF) }.joined(separator: ".")
        }

        public init(fromConfig: TunnelStartData, logger: Logger) {
            let allowedIPs = fromConfig.allowedIps.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var ipv4: [(String, String)] = []
            var ipv6: [(String, Int)] = []
            for ip in allowedIPs {
                let parts = ip.split(separator: "/")
                guard parts.count == 2 else {
                    logger.log(level: .error, "Invalid IP format: \(ip, privacy: .public)")
                    continue
                }
                let addr = String(parts[0])
                let mask = String(parts[1])
                if let _ = IPv4Address(addr), let cidr = Int(mask) {
                    ipv4.append((addr, Self.cidrToMask(cidr)))
                } else if let _ = IPv6Address(addr) {
                    if let prefix = Int(mask) {
                        ipv6.append((addr, prefix))
                    } else {
                        logger.log(level: .error, "Invalid IPv6 prefix length: \(mask, privacy: .public) for address \(addr, privacy: .public)")
                    }
                } else {
                    logger.log(level: .error, "Invalid IP address: \(ip, privacy: .public)")
                }
            }
            self.ipv4Addrs = ipv4
            self.ipv6Addrs = ipv6
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelConfig = extractTunnelConfiguration() else {
            let error = NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tunnel configuration is missing or invalid."])
            self.logger.log(level: .error, "Tunnel configuration is missing or invalid.")
            completionHandler(error)
            return
        }

        os_log("Starting tunnel with configuration: %{public}@", String(describing: tunnelConfig))

        guard let endpoint = Endpoint(from: tunnelConfig.endpoint) else {
            let error = NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint format: \(tunnelConfig.endpoint)"])
            self.logger.log(level: .error, "Invalid endpoint format: \(tunnelConfig.endpoint, privacy: .public)")
            completionHandler(error)
            return
        }

        let networkSettings = createNetworkSettings(tunnelConfig: tunnelConfig)

        applyNetworkSettings(networkSettings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completionHandler(error)
                return
            }

            let (privateKey, publicKey, presharedKey) = self.createKeys(from: tunnelConfig)
            let tunnelConfiguration = self.createTunnelConfiguration(
                tunnelConfig: tunnelConfig,
                endpoint: endpoint,
                privateKey: privateKey,
                publicKey: publicKey,
                presharedKey: presharedKey
            )

            do {
                try self.adapter.start(tunnelConfiguration: tunnelConfiguration)
            } catch {
                self.logger.log(level: .error, "Failed to start adapter with error: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
                return
            }

            self.logger.log(level: .default, "Tunnel started successfully")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        self.logger.log(level: .default, "\(#function)")
        os_log("\(#function)")
        self.adapter.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        self.logger.log(level: .default, "\(#function)")
        os_log("\(#function)")
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        self.logger.log(level: .default, "\(#function)")
        os_log("\(#function)")
        completionHandler()
    }

    override func wake() {
        self.logger.log(level: .default, "\(#function)")
        os_log("\(#function)")
    }

    // MARK: - Helpers

    private func extractTunnelConfiguration() -> TunnelStartData? {
        guard let providerConfig = (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration as? [String: Any] else {
            return nil
        }
        return try? TunnelStartData.from(dictionary: providerConfig)
    }


    private func parseAddresses(from addressString: String) -> [IpAddrMask] {
        var addresses: [IpAddrMask] = []

        for addr in addressString.split(separator: ",").map({ String($0.trimmingCharacters(in: .whitespaces)) }) {
            if let addr_mask = IpAddrMask(fromString: addr) {
                addresses.append(addr_mask)
            }
        }

        self.logger.log(level: .debug, "Parsed addresses: \(addresses, privacy: .public)")
        return addresses
    }

    private func createNetworkSettings(
        tunnelConfig: TunnelStartData,
    ) -> NEPacketTunnelNetworkSettings {
        // The endpoint is unused here
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let addresses = parseAddresses(from: tunnelConfig.address)
        let allowedIPs = switch tunnelConfig.traffic {
            case .All:
                [
                    IpAddrMask(address: IPv4Address.any, cidr: 0),
                    IpAddrMask(address: IPv6Address.any, cidr: 0)
                ]
            case .Predefined:
                parseAddresses(from: tunnelConfig.allowedIps)
        }

        let (ipv4IncludedRoutes, ipv6IncludedRoutes) = createRoutes(
            addresses: addresses,
            allowedIPs: allowedIPs
        )

        // IPv4 addresses
        let addrs_v4 = addresses.filter { $0.address is IPv4Address }
            .map { String(describing: $0.address) }
        let masks_v4 = addresses.filter { $0.address is IPv4Address }
            .map { String(describing: $0.mask()) }
        let ipv4Settings = NEIPv4Settings(addresses: addrs_v4, subnetMasks: masks_v4)
        ipv4Settings.includedRoutes = ipv4IncludedRoutes
        networkSettings.ipv4Settings = ipv4Settings

        // IPv6 addresses
        let addrs_v6 = addresses.filter { $0.address is IPv6Address }
            .map { String(describing: $0.address) }
        let masks_v6 = addresses.filter { $0.address is IPv6Address }
            .map { NSNumber(value: $0.cidr) }
        let ipv6Settings = NEIPv6Settings(addresses: addrs_v6, networkPrefixLengths: masks_v6)
        ipv6Settings.includedRoutes = ipv6IncludedRoutes
        networkSettings.ipv6Settings = ipv6Settings

        // DNS settings
        let dnsRecords = tunnelConfig.dns?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []
        self.logger.log("Parsed the following DNS servers: \(dnsRecords, privacy: .public)")
        if !dnsRecords.isEmpty {
            var searchDomains: [String] = []
            var dnsServers: [String] = []
            for record in dnsRecords {
                if IPv4Address(record) != nil || IPv6Address(record) != nil {
                    self.logger.log("Valid DNS server: \(record, privacy: .public)")
                    dnsServers.append(record)
                } else {
                    self.logger.log("Invalid DNS server format: \(record, privacy: .public), assuming it's a domain name")
                    searchDomains.append(record)
                }
            }

            self.logger.log("Setting DNS servers: \(dnsServers, privacy: .public)")
            self.logger.log("Setting search domains: \(searchDomains, privacy: .public)")
            let dnsSettings = NEDNSSettings(servers: dnsServers)
            dnsSettings.searchDomains = searchDomains
            networkSettings.dnsSettings = dnsSettings
        }

        return networkSettings
    }

    /// Return array of routes for IPv4 and IPv6.
    private func createRoutes(addresses: [IpAddrMask], allowedIPs: [IpAddrMask]) -> (
        [NEIPv4Route],
        [NEIPv6Route]
    ) {
        var ipv4IncludedRoutes = [NEIPv4Route]()
        var ipv6IncludedRoutes = [NEIPv6Route]()

        // Routes to interface addresses.
        for addr_mask in addresses {
            if addr_mask.address is IPv4Address {
                let route = NEIPv4Route(destinationAddress: "\(addr_mask.address)",
                                        subnetMask: "\(addr_mask.mask())")
                route.gatewayAddress = "\(addr_mask.address)"
                ipv4IncludedRoutes.append(route)
            } else if addr_mask.address is IPv6Address {
                let route = NEIPv6Route(
                    destinationAddress: "\(addr_mask.address)",
                    networkPrefixLength: NSNumber(value: addr_mask.cidr)
                )
                route.gatewayAddress = "\(addr_mask.address)"
                ipv6IncludedRoutes.append(route)
            }
        }

        // Routes to peer's allowed IPs.
        for addr_mask in allowedIPs {
            if addr_mask.address is IPv4Address {
                ipv4IncludedRoutes.append(
                    NEIPv4Route(destinationAddress: "\(addr_mask.address)",
                                subnetMask: "\(addr_mask.mask())"))
            } else if addr_mask.address is IPv6Address {
                ipv6IncludedRoutes.append(
                    NEIPv6Route(destinationAddress: "\(addr_mask.address)",
                                networkPrefixLength: NSNumber(value: addr_mask.cidr)))
            }
        }

        return (ipv4IncludedRoutes, ipv6IncludedRoutes)
    }

    private func applyNetworkSettings(_ networkSettings: NEPacketTunnelNetworkSettings, completion: @escaping (Error?) -> Void) {
        self.setTunnelNetworkSettings(networkSettings) { error in
            if error != nil {
                self.logger.log(level: .default, "Set tunnel network settings returned an error \(error, privacy: .public)")
            }
            completion(error)
        }
    }

    private func createKeys(from tunnelConfig: TunnelStartData) -> (privateKey: String, publicKey: String, presharedKey: String?) {
        return (
            tunnelConfig.privateKey,
            tunnelConfig.publicKey,
            tunnelConfig.presharedKey
        )
    }

    private func createTunnelConfiguration(
        tunnelConfig: TunnelStartData,
        endpoint: Endpoint,
        privateKey: String,
        publicKey: String,
        presharedKey: String?
    ) -> TunnelConfiguration {
        let interfaceConfiguration = InterfaceConfiguration(privateKey: privateKey)
        let peer = Peer(publicKey: publicKey, preSharedKey: presharedKey, endpoint: endpoint)
        return TunnelConfiguration(name: tunnelConfig.locationName, interface: interfaceConfiguration, peers: [peer])
    }
}
