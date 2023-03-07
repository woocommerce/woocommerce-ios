/// Represent a WCPay Payment Intent Entity.
///
public struct RemotePaymentIntent: Decodable {
    public let id: String // e.g. pi_123456789012345678901234
    public let status: WCPayPaymentIntentStatusEnum

    public init(
        id: String,
        status: WCPayPaymentIntentStatusEnum
    ) {
        self.id = id
        self.status = status
    }

    /// The public initializer for a WCPay Payment Intent.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let status = try container.decode(WCPayPaymentIntentStatusEnum.self, forKey: .status)

        self.init(
            id: id,
            status: status
        )
    }
}

private extension RemotePaymentIntent {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case status = "status"
    }
}
