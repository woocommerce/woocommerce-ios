/// Mapper:
///
struct WCPayConnectionTokenMapper: Mapper {

    /// Site Identifier associated to the refund that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Refund Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into a single Refund.
    ///
    func map(response: Data) throws -> WCPayConnectionToken {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(WCPayConnectionTokenEnvelope.self, from: response).token
    }
}


/// WCPayConnectionTokenEnvelope Disposable Entity
///
/// `Load connection Token` endpoint returns the requested order refund document in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct WCPayConnectionTokenEnvelope: Decodable {
    let token: WCPayConnectionToken

    private enum CodingKeys: String, CodingKey {
        case token = "data"
    }
}
