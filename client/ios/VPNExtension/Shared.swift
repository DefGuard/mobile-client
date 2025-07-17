//
//  THIS IS A SIMPLE TEMPORARY SOLUTION TO SHARE SOME TYPES BETWEEN THE POD AND VPNEXTENSION
//  WE SHOULD PROBABLY COME UP WITH A BETTER SOLUTION IN THE FUTURE
//

import Foundation

public enum TunnelTraffic: String, Codable {
    case All = "all"
    case Predefined = "predefined"
}

public struct TunnelStartData: Codable {
    public var publicKey: String
    public var privateKey: String
    public var address: String
    public var dns: String?
    public var endpoint: String
    public var allowedIps: String
    public var keepalive: Int
    public var presharedKey: String?
    public var traffic: TunnelTraffic
    public var locationName: String
    public var locationId: Int
    public var instanceId: Int
}

struct ActiveTunnelData: Codable {
    var locationId: Int
    var instanceId: Int
    var traffic: TunnelTraffic
    
    init(fromConfig: TunnelStartData) {
        self.locationId = fromConfig.locationId
        self.instanceId = fromConfig.instanceId
        self.traffic = fromConfig.traffic
    }
}

enum WireguardEvent: String {
    case tunnelUp = "tunnel_up"
    case tunnelDown = "tunnel_down"
    case tunnelWaiting = "tunnel_waiting"
}
