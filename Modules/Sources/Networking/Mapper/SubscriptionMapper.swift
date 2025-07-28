import Foundation

/// Mapper: `Subscription`
///
struct SubscriptionMapper: Mapper {
    /// Site we're parsing `Subscription` for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Subscription endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `Subscription`.
    ///
    func map(response: Data) throws -> Subscription {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(SubscriptionEnvelope.self, from: response).subscription
        } else {
            return try decoder.decode(Subscription.self, from: response)
        }
    }
}


/// SubscriptionEnvelope Disposable Entity:
/// Load Subscription endpoint returns the subscription in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct SubscriptionEnvelope: Decodable {
    let subscription: Subscription

    private enum CodingKeys: String, CodingKey {
        case subscription = "data"
    }
}
