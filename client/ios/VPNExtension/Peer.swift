//
//  Peer.swift
//  Pods
//
//  Created by Aleksander on 04/07/2025.
//

import Foundation

public struct Peer {
    public var publicKey: KeyBytes
    public var preSharedKey: KeyBytes?
    public var endpoint: Endpoint?
    public var lastHandshake: Date?
    public var txBytes: UInt64?
    public var rxBytes: UInt64?
    public var persistentKeepAlive: UInt16?
    public var allowedIPs = [IpAddrMask]()

    public init(publicKey: KeyBytes) {
        self.publicKey = publicKey
    }
}
