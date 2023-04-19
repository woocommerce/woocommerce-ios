import Foundation

/// Mapper: `Subscription` List
///
struct SubscriptionListMapper: Mapper {
    /// Site we're parsing `Subscription`s for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Subscription endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[Subscription]`.
    ///
    func map(response: Data) throws -> [Subscription] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        do {
            return try decoder.decode(SubscriptionListEnvelope.self, from: response).subscriptions
        } catch {
            return try decoder.decode([Subscription].self, from: response)
        }
    }
}


/// SubscriptionListEnvelope Disposable Entity:
/// Load Subscriptions endpoint returns the subscriptions in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct SubscriptionListEnvelope: Decodable {
    let subscriptions: [Subscription]

    private enum CodingKeys: String, CodingKey {
        case subscriptions = "data"
    }
}
