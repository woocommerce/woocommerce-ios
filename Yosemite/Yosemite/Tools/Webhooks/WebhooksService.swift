import Foundation
import Networking

public final class WebhooksService: ObservableObject {
    private let siteID: Int64
    public var remote: WebhooksRemote

    public init(siteID: Int64, credentials: Credentials) {
        self.siteID = siteID
        self.remote = WebhooksRemote(network: AlamofireNetwork(credentials: credentials))
    }

    /// Lists all site's webhooks by mapping `Networking.Webhook` to `Yosemite.Webhook` objects
    ///
    @MainActor
    public func listAllWebhooks() async throws -> [Webhook] {
        let webhooksFromRemote = try await remote.listAllWebhooks(for: siteID)

        let webhooks = webhooksFromRemote.map {
            Webhook(name: $0.name,
                    topic: $0.topic,
                    deliveryURL: $0.deliveryURL)
        }

        return webhooks
    }
}
