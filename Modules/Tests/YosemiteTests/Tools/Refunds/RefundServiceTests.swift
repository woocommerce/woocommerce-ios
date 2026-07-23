import Foundation
import Testing
import YosemiteTestHelpers
@testable import Networking
@testable import Storage
@testable import Yosemite

/// RefundService Unit Tests
///
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct RefundServiceTests {

    /// Mock Storage: InMemory
    ///
    private let storageManager: MockStorageManager

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private let network: MockNetwork

    private let service: RefundService

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 999

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 560

    init() {
        storageManager = MockStorageManager()
        network = MockNetwork()
        service = RefundService(remote: RefundsRemote(network: network), storageManager: storageManager)
    }

    // MARK: - previewRefund

    /// Verifies that `previewRefund` returns the server-calculated totals.
    ///
    @Test func previewRefund_returns_server_calculated_totals() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "refund-preview")

        // When
        let preview = try await service.previewRefund(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        #expect(preview.total == Decimal(string: "29.70"))
        #expect(preview.maxRefundable == Decimal(string: "50.00"))
    }

    /// Verifies that `previewRefund` does not persist anything (preview is read-only).
    ///
    @Test func previewRefund_does_not_persist_anything() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "refund-preview")

        // When
        _ = try await service.previewRefund(siteID: sampleSiteID,
                                            orderID: sampleOrderID,
                                            lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Refund.self) == 0)
    }

    /// Verifies that `previewRefund` forwards the `noRestRoute` failure that signals
    /// v4 is unavailable, so callers can fall back to v3.
    ///
    @Test func previewRefund_when_route_not_registered_then_throws_noRestRoute() async {
        // Given
        network.simulateResponse(requestUrlSuffix: "refunds/preview", filename: "restnoroute_error")

        // When / Then
        await #expect(throws: DotcomError.noRestRoute()) {
            try await service.previewRefund(siteID: sampleSiteID,
                                            orderID: sampleOrderID,
                                            lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
    }

    /// Verifies that `previewRefund` forwards failures other than `noRestRoute` unchanged.
    ///
    @Test func previewRefund_relays_generic_failures() async {
        // Given
        network.simulateError(requestUrlSuffix: "refunds/preview", error: NetworkError.timeout())

        // When / Then
        await #expect(throws: NetworkError.timeout()) {
            try await service.previewRefund(siteID: sampleSiteID,
                                            orderID: sampleOrderID,
                                            lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
    }

    // MARK: - createRefund

    /// Verifies that `createRefund` persists the created refund.
    ///
    @Test func createRefund_persists_created_refund() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refund-v4")
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Refund.self) == 0)

        // When
        let refund = try await service.createRefund(siteID: sampleSiteID,
                                                    orderID: sampleOrderID,
                                                    reason: "Damaged item",
                                                    automaticRefund: true,
                                                    restockItems: true,
                                                    lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])

        // Then
        #expect(refund.refundID == 3266)
        // The v4 response carries no display fields: items follow the v3 negation contract
        // but keep empty names and zero prices until `retrieveRefund` backfills them.
        #expect(refund.items.count == 2)
        #expect(refund.items.first?.quantity == -2)
        #expect(refund.items.first?.name.isEmpty == true)
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Refund.self) == 1)
    }

    /// Verifies that `createRefund` forwards failures without persisting anything.
    ///
    @Test func createRefund_when_request_fails_then_throws_and_persists_nothing() async {
        // Given
        network.simulateError(requestUrlSuffix: "refunds", error: NetworkError.notFound())

        // When / Then
        await #expect(throws: NetworkError.notFound()) {
            try await service.createRefund(siteID: sampleSiteID,
                                           orderID: sampleOrderID,
                                           reason: "",
                                           automaticRefund: false,
                                           restockItems: true,
                                           lineItems: [.quantityBased(lineItemID: 50, quantity: 2)])
        }
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Refund.self) == 0)
    }
}
