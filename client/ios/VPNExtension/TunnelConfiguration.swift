//
//  TunnelConfiguration.swift
//  NetExt
//
//  Created by Adam on 19/06/2025.
//

import Foundation

public final class TunnelConfiguration {
    public var name: String?
    public var interface: InterfaceConfiguration
    public let peers: [PeerConfiguration]

    public init(name: String?, interface: InterfaceConfiguration, peers: [PeerConfiguration]) {
        self.interface = interface
        self.peers = peers
        self.name = name

        let peerPublicKeysArray = peers.map { $0.publicKey }
        let peerPublicKeysSet = Set<KeyBytes>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            fatalError("Two or more peers cannot have the same public key")
        }
    }
}

extension KeyBytes: Equatable, Hashable {
    public static func == (lhs: KeyBytes, rhs: KeyBytes) -> Bool {
        // Compare relevant properties for equality
        return lhs.rawBytes() == rhs.rawBytes()
    }

    public func hash(into hasher: inout Hasher) {
        // Combine relevant properties into the hasher
        hasher.combine(rawBytes())
    }
}

//extension TunnelConfiguration: Equatable {
//    public static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool {
//        return lhs.name == rhs.name &&
//            lhs.interface == rhs.interface &&
//            Set(lhs.peers) == Set(rhs.peers)
//    }
//}
