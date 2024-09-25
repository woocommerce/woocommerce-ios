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

    func createWebhook(_ webhook: AvailableWebhook, _ deliveryURLString: String) async throws {
        var topic: String
        switch webhook {
        case .orderCreated:
            topic = "order.created"
        case .couponCreated:
            topic = "coupon.created"
        case .customerCreated:
            topic = "customer.created"
        case .productCreated:
            topic = "product.created"
        }

        guard let url = URL(string: deliveryURLString) else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        let webhook = try await service.createWebhook(topic: topic, url: url)
    }
}
