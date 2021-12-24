/// Represent a WCPay Customer Entity.
///
public struct WCPayCustomer: Decodable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    /// The public initializer for the WCPay Customer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)

        self.init(id: id)
    }
}


private extension WCPayCustomer {
    enum CodingKeys: String, CodingKey {
        case id = "id"
    }
}
