/// Models the request to send for an OAuth token
///
/// - Note: See documentation at https://developers.google.com/identity/protocols/oauth2/native-app#exchange-authorization-code
struct OAuthTokenRequestBody: Encodable {
    let clientId: String
    let clientSecret: String
    let audience: String
    let code: String
    let rawCodeVerifier: String
    let grantType: String
    let redirectURI: String

    init(
        clientId: String,
        clientSecret: String,
        audience: String,
        code: String,
        codeVerifier: ProofKeyForCodeExchange.CodeVerifier,
        grantType: String,
        redirectURI: String
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.audience = audience
        self.code = code
        self.rawCodeVerifier = codeVerifier.rawValue
        self.grantType = grantType
        self.redirectURI = redirectURI
    }

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case audience
        case code
        case rawCodeVerifier = "code_verifier"
        case grantType = "grant_type"
        case redirectURI = "redirect_uri"
    }

    func asURLEncodedData() throws -> Data {
        let params = [
            (CodingKeys.clientId.rawValue, clientId),
            (CodingKeys.clientSecret.rawValue, clientSecret),
            (CodingKeys.code.rawValue, code),
            (CodingKeys.rawCodeVerifier.rawValue, rawCodeVerifier),
            (CodingKeys.grantType.rawValue, grantType),
            (CodingKeys.redirectURI.rawValue, redirectURI),
            // This is not in the spec at
            // https://developers.google.com/identity/protocols/oauth2/native-app#step-2:-send-a-request-to-googles-oauth-2.0-server
            // but we'll get an idToken that our backend considers invalid if omitted.
            (CodingKeys.audience.rawValue, audience),
        ]

        let items = params.map { URLQueryItem(name: $0.0, value: $0.1) }

        var components = URLComponents()
        components.queryItems = items

        // We can assume `query` to never be nil because we set `queryItems` in the line above.
        return Data(components.query!.utf8)
    }
}
