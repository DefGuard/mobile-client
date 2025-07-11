import Foundation
import Network

final class InterfaceConfiguration: Codable {
    var privateKey: String
    var addresses = [IpAddrMask]()
    var listenPort: UInt16?
    var mtu: UInt16?
    var dns = [IPAddress]()
    var dnsSearch = [String]()

    init(privateKey: String) {
        self.privateKey = privateKey
    }

    enum CodingKeys: String, CodingKey {
        case privateKey
    }
}

//extension InterfaceConfiguration: Equatable {
//    public static func == (lhs: InterfaceConfiguration, rhs: InterfaceConfiguration) -> Bool {
//        let lhsAddresses = lhs.addresses.filter { $0.address is IPv4Address } + lhs.addresses.filter { $0.address is IPv6Address }
//        let rhsAddresses = rhs.addresses.filter { $0.address is IPv4Address } + rhs.addresses.filter { $0.address is IPv6Address }
//
//        return lhs.privateKey == rhs.privateKey &&
//            lhsAddresses == rhsAddresses &&
//            lhs.listenPort == rhs.listenPort &&
//            lhs.mtu == rhs.mtu &&
//            lhs.dns == rhs.dns &&
//            lhs.dnsSearch == rhs.dnsSearch
//    }
//}
