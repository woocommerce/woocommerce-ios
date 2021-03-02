/// Represent a WCPay connection token Entity.
///
public struct WCPayConnectionToken: Decodable {
    public let token: String
    public let testMode: Bool

    public init(token: String, testMode: Bool) {
        self.token = token
        self.testMode = testMode
    }

    /// The public initializer for WCPay Connection Token.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let token = try container.decode(String.self, forKey: .secret)
        let testMode = try container.decode(Bool.self, forKey: .testMode)

        self.init(token: token, testMode: testMode)
    }
}


private extension WCPayConnectionToken {
    enum CodingKeys: String, CodingKey {
        case secret     = "secret"
        case testMode   = "test_mode"
    }
}
