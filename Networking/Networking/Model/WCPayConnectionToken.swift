public struct WCPayConnectionToken: Decodable {
    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64
    public let token: String

    public init(siteID: Int64, token: String) {
        self.siteID = siteID
        self.token = token
    }

    /// The public initializer for WCPay Connection Token.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let siteID = try container.decode(Int64.self, forKey: .siteID)
        let token = try container.decode(String.self, forKey: .token)

        self.init(siteID: siteID, token: token)
    }
}


/// Defines all of the Site Post CodingKeys
///
private extension WCPayConnectionToken {
    enum CodingKeys: String, CodingKey {
        case siteID = "site_ID"
        case token  = "token"
    }
}
