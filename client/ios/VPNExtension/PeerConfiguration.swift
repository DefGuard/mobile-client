//
//  PeerConfiguration.swift
//  NetExt
//
//  Created by Adam on 19/06/2025.
//

import Foundation

public struct PeerConfiguration {
    public var publicKey: KeyBytes
    public var preSharedKey: KeyBytes?
//    public var allowedIPs = [IPAddressRange]()
//    public var endpoint: Endpoint?
    public var persistentKeepAlive: UInt16?
    public var rxBytes: UInt64?
    public var txBytes: UInt64?
    public var lastHandshakeTime: Date?

    public init(publicKey: KeyBytes) {
        self.publicKey = publicKey
    }
}

//extension PeerConfiguration: Equatable {
//    public static func == (lhs: PeerConfiguration, rhs: PeerConfiguration) -> Bool {
//        return lhs.publicKey == rhs.publicKey &&
//            lhs.preSharedKey == rhs.preSharedKey &&
//            Set(lhs.allowedIPs) == Set(rhs.allowedIPs) &&
//            lhs.endpoint == rhs.endpoint &&
//            lhs.persistentKeepAlive == rhs.persistentKeepAlive
//    }
//}
//
//extension PeerConfiguration: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(publicKey)
//        hasher.combine(preSharedKey)
//        hasher.combine(Set(allowedIPs))
//        hasher.combine(endpoint)
//        hasher.combine(persistentKeepAlive)
//
//    }
//}
