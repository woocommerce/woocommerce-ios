import XCTest
@testable import Networking

final class WebhooksRemoteTests: XCTestCase {
    private var network: MockNetwork!
    private var sut: WebhooksRemote!
    private let sampleSiteID: Int64 = 1
    
    override func setUp() {
        super.setUp()
        network = MockNetwork()
        sut = WebhooksRemote(network: network)
    }
    
    override func tearDown() {
        network = nil
        sut = nil
        super.tearDown()
    }

    func test_listAllWebhooks_when_site_has_no_webhooks_then_returns_empty_response() async {
        // Given
        var webhooks: [Webhook] = []
        network.simulateResponse(requestUrlSuffix: "webhooks", filename: "empty-data-array")
        
        do {
            // When
            webhooks = try await sut.listAllWebhooks(for: sampleSiteID)
            // Then
            XCTAssertEqual(webhooks, [])
        } catch {
            XCTFail("Expected empty. Found \(webhooks)")
        }
    }
    
    func test_listAllWebhooks_when_site_has_single_webhook_then_parses_and_returns_single_webhook_successfully() async {
        // Given
        var webhook: Webhook?
        let expectedWebhook = Self.makeWebhookForTesting()
        network.simulateResponse(requestUrlSuffix: "webhooks", filename: "webhooks-multiple")
        
        do {
            // When
            webhook = try await sut.listAllWebhooks(for: sampleSiteID).first
            // Then
            XCTAssertEqual(webhook, expectedWebhook)
        } catch {
            XCTFail("Expected \(expectedWebhook). Got \(String(describing: webhook))")
        }
    }
    
    func test_listAllWebhooks_when_site_has_multiple_webhooks_then_parses_and_returns_multiple_webhooks_successfully() async {
        // Given
        var webhooks: [Webhook] = []
        let expectedWebhooks = Self.makeMultipleWebhooksForTesting()
        network.simulateResponse(requestUrlSuffix: "webhooks", filename: "webhooks-multiple")
        
        do {
            // When
            webhooks = try await sut.listAllWebhooks(for: sampleSiteID)
            // Then
            XCTAssertEqual(webhooks, expectedWebhooks)
        } catch {
            XCTFail("Expected \(expectedWebhooks). Got \(webhooks)")
        }
    }

    func test_listAllWebhooks_when_fails_then_throws_error() async {
        // Given
        let expectedError = NSError(domain: "Some error", code: 0)
        network.simulateError(requestUrlSuffix: "webhooks", error: expectedError)
        
        do {
            // When
            _ = try await sut.listAllWebhooks(for: sampleSiteID)
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
    
    func test_createWebhook_then_creates_and_returns_single_webhook_successfully() async {
        // Given
        let topic = "order.created"
        let url = URL(string: "https://server.site/1234")!
        var webhook: Webhook?
        let expectedWebhook = Self.makeWebhookForTesting()
        network.simulateResponse(requestUrlSuffix: "webhooks", filename: "webhooks-single")
        
        do {
            // When
            webhook = try await sut.createWebhook(for: sampleSiteID, topic: topic, url: url)
            // Then
            XCTAssertEqual(webhook, expectedWebhook)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_createWebhook_when_fails_then_throws_error() async {
        // Given
        let topic = "order.created"
        let url = URL(string: "https://server.site/1234")!
        let expectedError = NSError(domain: "Some error", code: 0)
        network.simulateError(requestUrlSuffix: "webhooks", error: expectedError)
        
        do {
            // When
            _ = try await sut.createWebhook(for: sampleSiteID, topic: topic, url: url)
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}

private extension WebhooksRemoteTests {
    static func makeWebhookForTesting() -> Webhook {
        Webhook(siteID: 1,
                name: "Webhook created on Sep 26, 2024 @ 02:16 AM",
                status: "active",
                topic: "order.updated",
                deliveryURL: URL(string: "https://server.site/1234")!)
    }
    
    static func makeMultipleWebhooksForTesting() -> [Webhook] {
        let firstWebhook = Self.makeWebhookForTesting()
        let secondWebhook = Webhook(siteID: 1,
                name: "Webhook created on Sep 26, 2024 @ 02:30 AM",
                status: "active",
                topic: "order.created",
                deliveryURL: URL(string: "https://server.site/1234")!)
        return [firstWebhook, secondWebhook]
    }
}
