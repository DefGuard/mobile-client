import Foundation
import Network

struct IpAddrMask: Codable, Equatable {
    let address: IPAddress
    let cidr: UInt8

    init(address: IPAddress, cidr: UInt8) {
        self.address = address
        self.cidr = cidr
    }

    enum CodingKeys: String, CodingKey {
        case address
        case cidr
    }

    /// Conform to `Encodable`.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address.rawValue, forKey: .address)
        try container.encode(cidr, forKey: .cidr)
    }

    /// Conform to `Decodable`.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let address_data = try values.decode(Data.self, forKey: .address)
        switch address_data.count {
            case 4:
                guard let ipv4 = IPv4Address(address_data) else {
                    throw DecodingError
                        .dataCorrupted(DecodingError.Context(
                            codingPath: decoder.codingPath, debugDescription: "Unable to decode IP v4 address"
                        ))

                }
                address = ipv4
            case 16:
                guard let ipv6 = IPv6Address(address_data) else {
                    throw DecodingError
                        .dataCorrupted(DecodingError.Context(
                            codingPath: decoder.codingPath, debugDescription: "Unable to decode IP v6 address"
                        ))

                }
                address = ipv6
            default:
                throw DecodingError.typeMismatch(IpAddrMask.self, DecodingError.Context(
                    codingPath: decoder.codingPath, debugDescription: "Invalid IP address length"
                ))
        }
        cidr = try values.decode(UInt8.self, forKey: .cidr)
    }

    /// Conform to `Equatable`.
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.address.rawValue == rhs.address.rawValue && lhs.cidr == rhs.cidr
    }
}
