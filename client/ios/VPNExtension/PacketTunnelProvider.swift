////
////  PacketTunnelProvider.swift
////  VPNExtension
////
////  Created by Aleksander on 08/07/2025.
////

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
        
        guard let (ipv4Addresses, ipv6Addresses) = parseAddresses(from: tunnelConfig.address) else {
            self.logger.log(level: .error, "Invalid address format: \(tunnelConfig.address, privacy: .public)")
            completionHandler(NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid address format: \(tunnelConfig.address)"]))
            return
        }
        
        let networkSettings = createNetworkSettings(
            tunnelConfig: tunnelConfig,
            ipv4Addresses: ipv4Addresses,
            ipv6Addresses: ipv6Addresses
        )
        
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
    

    private func parseAddresses(from addressString: String) -> (ipv4: [String], ipv6: [String])? {
        var ipv4Addresses: [String] = []
        var ipv6Addresses: [String] = []
        
        for addr in addressString.split(separator: ",").map({ String($0.trimmingCharacters(in: .whitespaces)) }) {
            if let _ = IPv4Address(addr) {
                ipv4Addresses.append(addr)
            } else if let _ = IPv6Address(addr) {
                ipv6Addresses.append(addr)
            } else {
                return nil
            }
        }
        
        self.logger.log(level: .default, "Parsed IPv4 addresses: \(ipv4Addresses, privacy: .public)")
        self.logger.log(level: .default, "Parsed IPv6 addresses: \(ipv6Addresses, privacy: .public)")
        
        return (ipv4Addresses, ipv6Addresses)
    }
    
    private func createNetworkSettings(
        tunnelConfig: TunnelStartData,
        ipv4Addresses: [String],
        ipv6Addresses: [String]
    ) -> NEPacketTunnelNetworkSettings {
//        The endpoint is unused here
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        let ipv4Settings = NEIPv4Settings(addresses: ipv4Addresses, subnetMasks: ipv4Addresses.map { _ in "255.255.255.255" })
        let ipv6Settings = NEIPv6Settings(addresses: ipv6Addresses, networkPrefixLengths: ipv6Addresses.map { _ in 128 })
        
        let routes = DestinationAddrs(fromConfig: tunnelConfig, logger: self.logger)
        self.logger.log("Parsed the following routes: IPv4: \(routes.ipv4Addrs, privacy: .public), IPv6: \(routes.ipv6Addrs, privacy: .public)")
        
        // IPv4 routes
        if !ipv4Addresses.isEmpty {
            var ipv4Routes: [NEIPv4Route] = []
            if tunnelConfig.traffic == .Predefined {
                self.logger.log("Using predefined routes for IPv4 traffic")
                for route in routes.ipv4Addrs {
                    ipv4Routes.append(NEIPv4Route(destinationAddress: route.0, subnetMask: route.1))
                }
            } else {
                self.logger.log("Using default route for IPv4 traffic")
                ipv4Routes.append(NEIPv4Route.default())
            }
            ipv4Settings.includedRoutes = ipv4Routes
            networkSettings.ipv4Settings = ipv4Settings
        }
        
        // IPv6 routes
        if !ipv6Addresses.isEmpty {
            var ipv6Routes: [NEIPv6Route] = []
            if tunnelConfig.traffic == .Predefined {
                self.logger.log("Using predefined routes for IPv6 traffic")
                for route in routes.ipv6Addrs {
                    ipv6Routes.append(NEIPv6Route(destinationAddress: route.0, networkPrefixLength: route.1 as NSNumber))
                }
            } else {
                self.logger.log("Using default route for IPv6 traffic")
                ipv6Routes.append(NEIPv6Route.default())
            }
            ipv6Settings.includedRoutes = ipv6Routes
            networkSettings.ipv6Settings = ipv6Settings
        }
        
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
