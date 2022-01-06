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

        return try decoder.decode(StripeAccountEnvelope.self, from: response).account
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
