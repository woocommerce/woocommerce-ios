import Foundation
import Yosemite
import SwiftUI

final class WebhooksViewModel: ObservableObject {
    private let service: WebhooksServiceProtocol

    @Published var webhooks: [Webhook] = []

    init(service: WebhooksServiceProtocol) {
        self.service = service
    }

    @MainActor
    func listAllWebhooks() async throws {
        webhooks = try await service.listAllWebhooks()
    }

    @discardableResult
    func createWebhook(_ webhook: AvailableWebhook, _ deliveryURLString: String) async throws -> Webhook {
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
        return try await service.createWebhook(topic: topic, url: url)
    }
}
