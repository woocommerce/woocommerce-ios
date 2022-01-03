import Foundation

/// Mapper: Stripe Account
///
struct StripeAccountMapper: Mapper {

    /// (Attempts) to convert a dictionary into an account.
    ///
    func map(response: Data) throws -> StripeAccount {
        let decoder = JSONDecoder()

        /// Needed for currentDeadline, which is given as a UNIX timestamp.
        /// Unfortunately other properties use other formats for dates, but we
        /// can cross that bridge when we need those decoded.
        decoder.dateDecodingStrategy = .secondsSince1970

        /// Detect the exceptional case where we got a response of data:[] indicating
        /// that the plugin is active but the merchant has not on-boarded (and therefore
        /// has no account.)
        if let _ = try? decoder.decode(StripeNullAccountEnvelope.self, from: response) {
            return StripeAccount.noAccount
        }

        return try decoder.decode(StripeAccountEnvelope.self, from: response).account
    }
}

private struct StripeNullAccountEnvelope: Decodable {
    let emptyArray: [String]

    private enum CodingKeys: String, CodingKey {
        case emptyArray = "data"
    }
}

/// StripeAccountEnvelope Disposable Entity
///
/// Account endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct StripeAccountEnvelope: Decodable {
    let account: StripeAccount

    private enum CodingKeys: String, CodingKey {
        case account = "data"
    }
}
