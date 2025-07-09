//
//  Endpoint.swift
//  Pods
//
//  Created by Aleksander on 04/07/2025.
//

import Network

public struct Endpoint {
    public let host: NWEndpoint.Host
    public let port: NWEndpoint.Port

    public init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.host = host
        self.port = port
    }
}
