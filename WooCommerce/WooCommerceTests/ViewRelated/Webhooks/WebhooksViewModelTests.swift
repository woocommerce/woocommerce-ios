import XCTest
import Yosemite
@testable import WooCommerce

final class MockWebhooksService: WebhooksServiceProtocol {
    var webhooks: [Webhook] = []

    func listAllWebhooks() async throws -> [Yosemite.Webhook] {
        webhooks
    }

    func createWebhook(topic: String, url: URL) async throws -> Yosemite.Webhook {
        Webhook(name: "name",
                status: "status",
                topic: "topic",
                deliveryURL: URL(string: "https://server.site/1234")!)
    }
}

final class WebhooksViewModelTests: XCTestCase {

    func test_listAllWebhooks_when_site_has_no_webhooks_then_returns_empty() async {
        let sut = WebhooksViewModel(service: MockWebhooksService())
        var expectedWebhooks: [Webhook] = []
        
        do {
            try await sut.listAllWebhooks()
            XCTAssertEqual(sut.webhooks, expectedWebhooks)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
}
