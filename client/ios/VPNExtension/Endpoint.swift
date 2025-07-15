import Network

struct Endpoint: CustomStringConvertible, Codable {
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port

    init(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        self.host = host
        self.port = port
    }

    /// Custom initializer from String. Assume format "host:port".
    init?(from string: String) {
        let trimmedEndpoint = string.trimmingCharacters(in: .whitespaces)
        var endpointHost = trimmedEndpoint

        // Extract host, supporting IPv4, IPv6, and domains
        if trimmedEndpoint.hasPrefix("[") { // IPv6 with port, e.g. [fd00::1]:51820
            if let closing = trimmedEndpoint.firstIndex(of: "]") {
                endpointHost = String(trimmedEndpoint[trimmedEndpoint.index(after: trimmedEndpoint.startIndex)..<closing])
            }
        } else if trimmedEndpoint.contains(":") {
            let parts = trimmedEndpoint.split(separator: ":", omittingEmptySubsequences: false)
            if parts.count > 1 {
                endpointHost = parts.dropLast().joined(separator: ":")
            }
        }

        let endpointPort: Network.NWEndpoint.Port
        if let portPart = trimmedEndpoint.split(separator: ":").last, let port = Int(portPart),
           let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) {
            endpointPort = nwPort
        } else {
            return nil
        }

        self.host = NWEndpoint.Host(endpointHost)
        self.port = endpointPort
    }

    /// A textual representation of this instance. Required for `CustomStringConvertible`.
    var description: String {
        "Endpoint(\(host):\(port))"
    }

    var hostString: String {
        "\(host)"
    }

    enum CodingKeys: String, CodingKey {
        case host
        case port
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(host)", forKey: .host)
        try container.encode(port.rawValue, forKey: .port)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        host = try NWEndpoint.Host(values.decode(String.self, forKey: .host))
        port = try NWEndpoint.Port(rawValue: values.decode(UInt16.self, forKey: .port)) ?? 0
    }

    func asNWEndpoint() -> NWEndpoint {
        NWEndpoint.hostPort(host: host, port: port)
    }
}
