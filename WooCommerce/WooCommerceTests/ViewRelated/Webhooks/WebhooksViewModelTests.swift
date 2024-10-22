import XCTest
import Yosemite
@testable import WooCommerce

final class MockWebhooksService: WebhooksServiceProtocol {
    var hasWebhooks: Bool = true
    var hasError: Bool = false

    func listAllWebhooks() async throws -> [Yosemite.Webhook] {
        if hasError {
            throw NSError(domain: "Error", code: 0)
        }
        if hasWebhooks {
            return makeWebhooksForTesting()
        } else {
            return []
        }
    }

    func createWebhook(topic: String = "order.created",
                       url: URL = URL(string: "https://server.site/1234")!) async throws -> Yosemite.Webhook {
        let webhook = Webhook(name: "some name",
                              status: "active",
                              topic: topic,
                              deliveryURL: url)
        if hasError {
            throw NSError(domain: "Error", code: 0)
        } else {
            return webhook
        }
    }

    private func makeWebhooksForTesting() -> [Webhook] {
        let firstWebhook =  Webhook(name: "Webhook created on Sep 26, 2024 @ 02:16 AM",
                                    status: "active",
                                    topic: "order.updated",
                                    deliveryURL: URL(string: "https://server.site/1234")!)
        let secondWebhook = Webhook(name: "Webhook created on Sep 26, 2024 @ 02:30 AM",
                                    status: "active",
                                    topic: "order.created",
                                    deliveryURL: URL(string: "https://server.site/1234")!)
        return [firstWebhook, secondWebhook]
    }
}

final class WebhooksViewModelTests: XCTestCase {
    func test_listAllWebhooks_when_site_has_no_webhooks_then_returns_empty() async {
        // Given
        let service = MockWebhooksService()
        service.hasWebhooks = false

        let sut = WebhooksViewModel(service: service)
        let expectedWebhooks: [Webhook] = []

        do {
            // When
            try await sut.listAllWebhooks()
            // Then
            XCTAssertEqual(sut.webhooks, expectedWebhooks)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_listAllWebhooks_when_site_has_webhooks_then_returns_expected_webhooks() async {
        // Given
        let service = MockWebhooksService()
        service.hasWebhooks = true

        let sut = WebhooksViewModel(service: service)
        let expectedWebhooks: [Webhook] = [
            Webhook(name: "Webhook created on Sep 26, 2024 @ 02:16 AM",
                                        status: "active",
                                        topic: "order.updated",
                                        deliveryURL: URL(string: "https://server.site/1234")!),
            Webhook(name: "Webhook created on Sep 26, 2024 @ 02:30 AM",
                                        status: "active",
                                        topic: "order.created",
                                        deliveryURL: URL(string: "https://server.site/1234")!)
        ]

        do {
            // When
            try await sut.listAllWebhooks()
            // Then
            XCTAssertEqual(sut.webhooks, expectedWebhooks)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_listAllWebhooks_when_there_is_an_error_then_returns_error() async {
        // Given
        let service = MockWebhooksService()
        service.hasError = true

        let sut = WebhooksViewModel(service: service)
        let expectedError = NSError(domain: "Error", code: 0)

        do {
            // When
            try await sut.listAllWebhooks()
            XCTFail("Expected error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    func test_createWebhook_ok() async throws {
        // Given
        let service = MockWebhooksService()
        let sut = WebhooksViewModel(service: service)
        let topic = AvailableWebhook.orderCreated
        let deliveryURLString = "https://server.site/1234"

        // When
        let expectedWebhook = try await sut.createWebhook(topic, deliveryURLString)

        // Then
        XCTAssertEqual(expectedWebhook.name, "some name")
        XCTAssertEqual(expectedWebhook.topic, "order.created")
        XCTAssertEqual(expectedWebhook.status, "active")
        XCTAssertEqual(expectedWebhook.deliveryURL, URL(string: "https://server.site/1234")!)
    }

    func test_createWebhook_when_there_is_an_error_then_returns_error() async {
        // Given
        let service = MockWebhooksService()
        service.hasError = true
        let expectedError = NSError(domain: "Error", code: 0)
        let sut = WebhooksViewModel(service: service)

        do {
            // When
            try await sut.createWebhook(.couponCreated, "some delivery url")
            // Then
            XCTFail("Expected failure, but got success.")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}
