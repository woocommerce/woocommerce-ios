import Foundation

public class WebhooksRemote: Remote {
    public func listAllWebhooks(for siteID: Int64) async throws -> [Webhook] {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: "webhooks",
                                     availableAsRESTRequest: true)
        let mapper = WebhookListMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    public func createWebhook(for siteID: Int64, topic: String, url: URL) async throws -> Webhook {
        let parameters = [
            "topic": "\(topic)",
            "delivery_url": "\(url.absoluteString)"
        ]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: "webhooks",
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = WebhookMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }
}
