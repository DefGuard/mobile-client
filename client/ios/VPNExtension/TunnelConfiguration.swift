import Foundation
import NetworkExtension

final class TunnelConfiguration: Codable {
    var name: String
    var interface: InterfaceConfiguration
    var peers: [Peer]

    init(name: String, interface: InterfaceConfiguration, peers: [Peer]) {
        self.interface = interface
        self.peers = peers
        self.name = name

        let peerPublicKeysArray = peers.map { $0.publicKey }
        let peerPublicKeysSet = Set<String>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            fatalError("Two or more peers cannot have the same public key")
        }
    }

    // Only encode these properties.
    enum CodingKeys: String, CodingKey {
        case name
        case interface
        case peers
    }
}

//extension TunnelConfiguration: Equatable {
//    public static func == (lhs: TunnelConfiguration, rhs: TunnelConfiguration) -> Bool {
//        return lhs.name == rhs.name &&
//            lhs.interface == rhs.interface &&
//            Set(lhs.peers) == Set(rhs.peers)
//    }
//}
