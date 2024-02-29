/// Representation of SCPWallet
public struct Wallet: Codable, Equatable {
    public let type: String?
}

extension Wallet {
    enum CodingKeys: String, CodingKey {
        case type = "type"
    }
}
