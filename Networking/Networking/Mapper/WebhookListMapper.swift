import Foundation

struct WebhookListMapper: Mapper {
    /// Identifier associated to the webhooks that will be parsed from a given site
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints for webhook don't return the SiteID
    ///
    let siteID: Int64

    /// Attempts to convert a dictionary into a `[Webhook]` object
    ///
    func map(response: Data) throws -> [Webhook] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            let decodedResponse = try decoder.decode(WebhookListEnvelope.self, from: response).webhooks
            return decodedResponse
        } else {
            let decodedResponse = try decoder.decode([Webhook].self, from: response)
            return decodedResponse
        }
    }
}

struct WebhookListEnvelope: Decodable {
    let webhooks: [Webhook]

    private enum CodingKeys: String, CodingKey {
        case webhooks = "data"
    }
}
