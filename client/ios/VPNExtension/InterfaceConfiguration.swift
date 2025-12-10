import Foundation
import NetworkExtension

final class InterfaceConfiguration: Codable {
    var privateKey: String
    var addresses: [IpAddrMask] = []
    var listenPort: UInt16?
    var mtu: UInt32?
    var dns: [String] = []
    var dnsSearch: [String] = []

    init(privateKey: String) {
        self.privateKey = privateKey
    }
}
