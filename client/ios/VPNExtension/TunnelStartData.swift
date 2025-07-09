//
//  TunnelStartData.swift
//  Runner
//
//  Created by Aleksander on 08/07/2025.
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
    
    public func endpointPort() -> Int? {
        guard let url = URL(string: endpoint) else { return nil }
        return url.port
    }
    
    public func endpointHost() -> String? {
        guard let url = URL(string: endpoint) else { return nil }
        return url.host
    }
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
