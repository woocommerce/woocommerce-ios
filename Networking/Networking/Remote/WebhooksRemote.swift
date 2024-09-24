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
}
