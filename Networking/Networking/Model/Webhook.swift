import Foundation
import Codegen

/// Represents a Webhook entity:
/// https://woocommerce.github.io/woocommerce-rest-api-docs/#webhooks
///
public struct Webhook: Codable {
    /// The siteID for the webhook
    public let siteID: Int64

    public let name: String?
    public let topic: String
    public let deliveryURL: URL

    /// Webhook struct initializer
    ///
    public init(siteID: Int64,
                name: String?,
                topic: String,
                deliveryURL: URL) {
        self.siteID = siteID
        self.name = name
        self.topic = topic
        self.deliveryURL = deliveryURL
    }

    /// Public initializer for the Webhook
    ///
    public init(from decoder: any Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw WebhookDecodingError.missingSiteID
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let topic = try container.decode(String.self, forKey: .topic)
        let deliveryURL = try container.decode(URL.self, forKey: .deliveryURL)

        self.init(siteID: siteID,
                  name: name,
                  topic: topic,
                  deliveryURL: deliveryURL)
    }
}

extension Webhook {
    enum CodingKeys: String, CodingKey {
        case name
        case topic
        case deliveryURL = "delivery_url"
    }

    enum WebhookDecodingError: Error {
        case missingSiteID
    }
}
