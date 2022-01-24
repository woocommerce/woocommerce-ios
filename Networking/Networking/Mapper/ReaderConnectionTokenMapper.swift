/// Mapper: Card reader connection token
///
struct ReaderConnectionTokenMapper: Mapper {

    /// (Attempts) to convert a dictionary into a connection token.
    ///
    func map(response: Data) throws -> ReaderConnectionToken {
        let decoder = JSONDecoder()

        return try decoder.decode(ReaderConnectionTokenEnvelope.self, from: response).token
    }
}


/// ReaderConnectionTokenEnvelope Disposable Entity
///
/// `Load connection Token` endpoint returns the requested connection token and test mode in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ReaderConnectionTokenEnvelope: Decodable {
    let token: ReaderConnectionToken

    private enum CodingKeys: String, CodingKey {
        case token = "data"
    }
}
