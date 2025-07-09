////
////  PacketTunnelProvider.swift
////  VPNExtension
////
////  Created by Aleksander on 08/07/2025.
////

import NetworkExtension
import os
import Network

// Add the event types for the extension
enum VPNEventType: String {
    case tunnelUp = "tunnel_up"
    case tunnelDown = "tunnel_down"
    case tunnelError = "tunnel_error"
    case connectionStatusChanged = "connection_status_changed"
    case bytesTransferred = "bytes_transferred"
}

public func toDictionary<T: Encodable>(_ encodable: T) -> [String: Any]? {
    do {
        let data = try JSONEncoder().encode(encodable)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        return jsonObject as? [String: Any]
    } catch {
        print("Error converting to dictionary:", error)
        return nil
    }
}

public func fromDictionary<T: Decodable>(_ dictionary: [String: Any], to type: T.Type) -> T? {
    do {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let decodedObject = try JSONDecoder().decode(type, from: data)
        return decodedObject
    } catch {
        print("Error converting from dictionary:", error)
        return nil
    }
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
                    logger.log(level: .error, "Invalid IP format: \(ip)")
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
                        logger.log(level: .error, "Invalid IPv6 prefix length: \(mask) for address \(addr)")
                    }
                } else {
                    logger.log(level: .error, "Invalid IP address: \(ip)")
                }
            }
            self.ipv4Addrs = ipv4
            self.ipv6Addrs = ipv6
        }
    }
    

    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        var config: TunnelStartData? = nil
        if let providerConfig = (self.protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration as? [String: Any] {
            config = fromDictionary(providerConfig, to: TunnelStartData.self)
        }
        guard let tunnelConfig = config else {
            self.logger.log(level: .error, "Tunnel configuration is missing or invalid.")
            completionHandler(NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tunnel configuration is missing or invalid."]))
            return
        }
        os_log("Starting tunnel with configuration: %{public}@", String(describing: tunnelConfig))

        
        // Extract host for tunnelRemoteAddress, supporting IPv4, IPv6, and DNS
        let endpoint = tunnelConfig.endpoint.trimmingCharacters(in: .whitespaces)
        var endpointHost = endpoint
        if endpoint.hasPrefix("[") { // IPv6 with port, e.g. [fd00::1]:51820
            if let closing = endpoint.firstIndex(of: "]") {
                endpointHost = String(endpoint[endpoint.index(after: endpoint.startIndex)..<closing])
            }
        } else if endpoint.contains(":") {
            let parts = endpoint.split(separator: ":", omittingEmptySubsequences: false)
            if parts.count > 1 {
                endpointHost = parts.dropLast().joined(separator: ":")
            }
        }
        

        let endpointPort = endpoint.split(separator: ":").last.flatMap { Int($0) } ?? 51820 // Default to 51820 if no port is specified
        os_log("Using endpoint host: %{public}@", String(describing: endpointHost))
        os_log("Using endpoint port: %{public}d", endpointPort)
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: endpointHost)
        
        var ipv4Addresses: [String] = []
        var ipv6Addresses: [String] = []
        
        for addr in tunnelConfig.address.split(separator: ",").map({ String($0.trimmingCharacters(in: .whitespaces)) }) {
            if let _ = IPv4Address(addr) {
                ipv4Addresses.append(addr)
            } else if let _ = IPv6Address(addr) {
                ipv6Addresses.append(addr)
            } else {
                self.logger.log(level: .error, "Invalid address format: \(addr)")
                completionHandler(NSError(domain: "VPNExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid address format: \(addr)"]))
                return
            }
        }
        
        let ipv4Settings = NEIPv4Settings(addresses: ipv4Addresses, subnetMasks: ipv4Addresses.map { _ in "255.255.255.255" })
        let ipv6Settings = NEIPv6Settings(addresses:  ipv6Addresses, networkPrefixLengths: ipv6Addresses.map { _ in 128 })

        let routes: DestinationAddrs = DestinationAddrs(fromConfig: tunnelConfig, logger: self.logger)
        os_log("PARSED ROUTES:  %{public}@  %{public}@", String(describing: routes.ipv4Addrs), String(describing: routes.ipv6Addrs))
        
        var ipv4Routes: [NEIPv4Route] = []
        
        if !ipv4Addresses.isEmpty {
            for route in routes.ipv4Addrs {
                os_log("ADDING v4 ROUTE:  %{public}@", String(describing: route))
                
                ipv4Routes.append(
                    NEIPv4Route(destinationAddress: route.0, subnetMask: route.1)
                )
            }
        }
        
        var ipv6Routes: [NEIPv6Route] = []
            
        if !ipv6Addresses.isEmpty {
            for route in routes.ipv6Addrs {
                os_log("ADDING v6 ROUTE:  %{public}@", String(describing: route))
                
                ipv6Routes.append(
                    NEIPv6Route(destinationAddress: route.0, networkPrefixLength: route.1 as NSNumber)
                )
            }
        }
        
        ipv4Settings.includedRoutes = ipv4Routes;
        ipv6Settings.includedRoutes = ipv6Routes;
        
        let dns_servers = tunnelConfig.dns?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []
        networkSettings.ipv4Settings = ipv4Settings
        networkSettings.ipv6Settings = ipv6Settings
        let dnsSettings = NEDNSSettings(servers: dns_servers)
        networkSettings.dnsSettings = dnsSettings
        self.setTunnelNetworkSettings(networkSettings) { error in
            self.logger.log(level: .default, "Set tunnel network settings returned \(error)")
            os_log("Set tunnel network settings returned \(error)")
            
            if error == nil {
                // Send tunnel up event

            }
            
            completionHandler(error)
        }

        // This end's key
        guard let privateKey = try? KeyBytes.fromString(s: tunnelConfig.privateKey) else {
            self.logger.log(level: .default, "Failed to create private key")
            os_log("Private key constructor failed")
            return
        }
        // The other end's key
        guard let publicKey = try? KeyBytes.fromString(s: tunnelConfig.publicKey) else {
            self.logger.log(level: .default, "Failed to create public key")
            os_log("Public key constructor failed")
            return
        }
        let host = NWEndpoint.Host(endpointHost)
        let port = NWEndpoint.Port(rawValue: UInt16(endpointPort)) ?? NWEndpoint.Port(rawValue: 51820)! // Default to 51820 if port is invalid
        let interfaceEndpoint = Endpoint(host: host, port: port)
        os_log("Using endpoint: %{public}@", String(describing: interfaceEndpoint))
        let interfaceConfiguration = InterfaceConfiguration(privateKey: privateKey, endpoint: interfaceEndpoint)
        let peer = PeerConfiguration(publicKey: publicKey)
        let tunnelConfiguration = TunnelConfiguration(name: tunnelConfig.locationName, interface: interfaceConfiguration, peers: [peer])
        self.adapter.start(tunnelConfiguration: tunnelConfiguration)

        self.logger.log(level: .default, "Tunnel started successfully")
        os_log("Tunnel started successfully")
        completionHandler(nil)
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
}
