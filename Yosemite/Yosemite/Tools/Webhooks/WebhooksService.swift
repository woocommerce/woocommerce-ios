import Foundation
import Networking

public protocol WebhooksServiceProtocol {
    func listAllWebhooks() async throws -> [Webhook]
    func createWebhook(topic: String, url: URL) async throws -> Webhook
}

public final class WebhooksService: WebhooksServiceProtocol, ObservableObject {
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
                    status: $0.status,
                    topic: $0.topic,
                    deliveryURL: $0.deliveryURL)
        }

        return webhooks
    }

    @MainActor
    public func createWebhook(topic: String, url: URL) async throws -> Webhook {
        let response = try await remote.createWebhook(for: siteID,
                                                      topic: topic,
                                                      url: url)
        return Webhook(name: response.name,
                       status: response.status,
                       topic: response.topic,
                       deliveryURL: response.deliveryURL)
    }
}
