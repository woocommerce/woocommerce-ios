/// Mapper: WCPay connection token
///
struct WCPayConnectionTokenMapper: Mapper {

    /// (Attempts) to convert a dictionary into a connection token.
    ///
    func map(response: Data) throws -> WCPayConnectionToken {
        let decoder = JSONDecoder()

        return try decoder.decode(WCPayConnectionTokenEnvelope.self, from: response).token
    }
}


// WCPayConnectionTokenEnvelope Disposable Entity
///
/// `Load connection Token` endpoint returns the requested connection token and test mode document in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct WCPayConnectionTokenEnvelope: Decodable {
    let token: WCPayConnectionToken

    private enum CodingKeys: String, CodingKey {
        case token = "data"
    }
}
