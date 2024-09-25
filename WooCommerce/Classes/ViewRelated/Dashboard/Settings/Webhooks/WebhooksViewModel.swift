import Foundation
import Yosemite
import SwiftUI

final class WebhooksViewModel: ObservableObject {
    var siteID: Int64 = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    var credentials: Credentials = ServiceLocator.stores.sessionManager.defaultCredentials ?? .init(authToken: "")
    var service: WebhooksService

    @Published var webhooks: [Webhook] = []

    init() {
        service = WebhooksService(siteID: siteID, credentials: credentials)
    }

    @MainActor
    func listAllWebhooks() async throws {
        do {
            webhooks = try await service.listAllWebhooks()
        } catch {
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }

    func createWebhook(_ deliveryURLString: String) async throws {
        // At the moment we only allow for the order.updated webhook, so it's hardcoded
        // On further iterations we can pass different selectable topics or custom actions down to the service.
        let topic = "order.updated"
        guard let url = URL(string: deliveryURLString) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        let webhook = try await service.createWebhook(topic: topic, url: url)
    }
}
