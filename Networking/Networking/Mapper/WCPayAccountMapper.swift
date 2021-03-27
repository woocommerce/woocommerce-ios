/// Mapper: WCPay account
///
struct WCPayAccountMapper: Mapper {

    /// (Attempts) to convert a dictionary into an account.
    ///
    func map(response: Data) throws -> WCPayAccount {
        let decoder = JSONDecoder()

        return try decoder.decode(WCPayAccountEnvelope.self, from: response).account
    }
}

/// WCPayAccountEnvelope Disposable Entity
///
/// Account endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct WCPayAccountEnvelope: Decodable {
    let account: WCPayAccount

    private enum CodingKeys: String, CodingKey {
        case account = "data"
    }
}
