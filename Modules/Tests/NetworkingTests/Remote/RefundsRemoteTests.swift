import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

/// Tests for the v4 refund endpoints (`previewRefund` / `createSimplifiedRefund`).
///
struct RefundsRemoteTests {
    /// Mock network to inject responses and capture issued requests.
    private let network = MockNetwork()

    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 560

    // MARK: - previewRefund

    @Test func previewRefund_issues_a_post_to_the_v4_preview_endpoint() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "refund-preview")

        // When
        _ = try await remote.previewRefund(for: sampleSiteID,
                                           orderID: sampleOrderID,
                                           lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.wooApiVersion == .mark4)
        #expect(request.method == .post)
        #expect(request.siteID == sampleSiteID)
        #expect(request.path == "refunds/preview")
    }

    @Test func previewRefund_sends_order_id_and_line_items_in_the_body() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "refund-preview")

        // When
        _ = try await remote.previewRefund(for: sampleSiteID,
                                           orderID: sampleOrderID,
                                           lineItems: [.quantityBased(lineItemID: 50, quantity: 2),
                                                       .amountBased(lineItemID: 51, refundTotal: 5.50)])

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["order_id"] as? NSNumber == NSNumber(value: sampleOrderID))

        let lineItems = try #require(request.parameters["line_items"] as? [[String: Any]])
        #expect(lineItems.count == 2)

        // A quantity-based line emits `line_item_id` + `quantity` only.
        let quantityLine = try #require(lineItems.first)
        #expect(quantityLine["line_item_id"] as? NSNumber == 50)
        #expect(quantityLine["quantity"] as? NSNumber == 2)
        #expect(quantityLine["refund_total"] == nil)

        // An amount-based line emits `line_item_id` + `refund_total` only.
        let amountLine = try #require(lineItems.last)
        #expect(amountLine["line_item_id"] as? NSNumber == 51)
        #expect(amountLine["refund_total"] as? NSNumber == 5.5)
        #expect(amountLine["quantity"] == nil)
    }

    @Test func previewRefund_parses_the_server_calculated_breakdown() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "refund-preview")

        // When
        let preview = try await remote.previewRefund(for: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        #expect(preview.total == Decimal(string: "25.30"))
        #expect(preview.maxRefundable == Decimal(string: "50.00"))
        #expect(preview.breakdown.products.items.count == 1)
    }

    @Test func previewRefund_when_the_route_is_not_registered_then_throws_noRestRoute() async throws {
        // Given a store without the v4 API (older WC or `rest-api-v4` flag off)
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "restnoroute_error")

        // When / Then
        await #expect(throws: DotcomError.noRestRoute()) {
            _ = try await remote.previewRefund(for: sampleSiteID,
                                               orderID: sampleOrderID,
                                               lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
    }

    @Test func previewRefund_relays_networking_errors() async throws {
        // Given no simulated response, so the network reports a not-found error
        let remote = RefundsRemote(network: network)

        // When / Then
        await #expect(throws: NetworkError.notFound()) {
            _ = try await remote.previewRefund(for: sampleSiteID,
                                               orderID: sampleOrderID,
                                               lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
    }

    // MARK: - createSimplifiedRefund

    @Test func createSimplifiedRefund_issues_a_post_to_the_v4_refunds_endpoint() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "simplified-refund")

        // When
        _ = try await remote.createSimplifiedRefund(for: sampleSiteID,
                                                    orderID: sampleOrderID,
                                                    reason: "reason",
                                                    automaticRefund: true,
                                                    restockItems: true,
                                                    lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.wooApiVersion == .mark4)
        #expect(request.method == .post)
        #expect(request.siteID == sampleSiteID)
        #expect(request.path == "refunds")
    }

    @Test func createSimplifiedRefund_sends_stringified_flags_line_items_and_no_amount() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "simplified-refund")

        // When
        _ = try await remote.createSimplifiedRefund(for: sampleSiteID,
                                                    orderID: sampleOrderID,
                                                    reason: "Item was damaged",
                                                    automaticRefund: true,
                                                    restockItems: false,
                                                    lineItems: [.quantityBased(lineItemID: 50, quantity: 2),
                                                                .amountBased(lineItemID: 51, refundTotal: 74)])

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["order_id"] as? NSNumber == NSNumber(value: sampleOrderID))
        #expect(request.parameters["reason"] as? String == "Item was damaged")
        #expect(request.parameters["api_refund"] as? String == "true")
        #expect(request.parameters["api_restock"] as? String == "false")

        // The server owns the math: the client never sends an amount.
        #expect(request.parameters["amount"] == nil)

        let lineItems = try #require(request.parameters["line_items"] as? [[String: Any]])
        #expect(lineItems.count == 2)
    }

    @Test func createSimplifiedRefund_parses_the_created_refund() async throws {
        // Given
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "simplified-refund")

        // When
        let refund = try await remote.createSimplifiedRefund(for: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             reason: "reason",
                                                             automaticRefund: false,
                                                             restockItems: true,
                                                             lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        #expect(refund.refundID == 3266)
        #expect(refund.siteID == sampleSiteID)
        #expect(refund.orderID == sampleOrderID)
        #expect(refund.items.count == 2)
    }

    @Test func createSimplifiedRefund_when_the_route_is_not_registered_then_throws_noRestRoute() async throws {
        // Given a store without the v4 API (older WC or `rest-api-v4` flag off)
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "restnoroute_error")

        // When / Then
        await #expect(throws: DotcomError.noRestRoute()) {
            _ = try await remote.createSimplifiedRefund(for: sampleSiteID,
                                                        orderID: sampleOrderID,
                                                        reason: "",
                                                        automaticRefund: false,
                                                        restockItems: true,
                                                        lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
    }
}
