/// Represent a card reader connection token Entity.
///
public struct ReaderConnectionToken: Decodable {
    public let token: String
    public let testMode: Bool

    public init(token: String, testMode: Bool) {
        self.token = token
        self.testMode = testMode
    }

    /// Public initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let token = try container.decode(String.self, forKey: .secret)
        let testMode = try container.decode(Bool.self, forKey: .testMode)

        self.init(token: token, testMode: testMode)
    }
}


private extension ReaderConnectionToken {
    enum CodingKeys: String, CodingKey {
        case secret     = "secret"
        case testMode   = "test_mode"
    }
}
