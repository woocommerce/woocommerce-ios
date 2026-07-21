import Testing
import Foundation
import Yosemite
import YosemiteTestHelpers
import Experiments
import enum NetworkingCore.NetworkError
import WooFoundation
@testable import PointOfSale
@testable import WooCommerce

/// Covers the v4 wire-in seams of `POSRefundSubmissionAdaptor`: review data built from the
/// server-calculated preview vs the local fallback, the preview-failure error, and routing the
/// submission through the simplified v4 create only when a preview was obtained.
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSRefundSubmissionAdaptorTests {

    private let siteID: Int64 = 123
    private let orderID: Int64 = 560

    @Test func prepareReviewData_when_preview_is_server_calculated_then_shows_server_totals_and_submits_via_v4() async throws {
        // Given
        let harness = makeHarness(previewResult: .success(preview()))
        let preparation = try await harness.adaptor.prepareRefund(for: posOrder())

        // When
        let reviewData = try await harness.adaptor.prepareReviewData(for: posOrder(),
                                                                     preparation: preparation,
                                                                     selectedItems: preparation.selectableItems,
                                                                     reason: nil)

        // Then the review shows the server-calculated totals, not the local math
        #expect(reviewData.formattedItemsSubtotal == "$27.00")
        #expect(reviewData.formattedTax == "$2.43")
        #expect(reviewData.formattedRefundTotal == "$29.43")

        // When submitting
        try await harness.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: preparation.selectableItems,
                                               reason: "Damaged item")

        // Then the simplified v4 create was dispatched instead of the v3 create
        #expect(harness.service.createRefundLineItems?.isEmpty == false)
        #expect(harness.service.createRefundReason == "Damaged item")
        #expect(harness.spy.dispatchedV3Create == false)
    }

    @Test func prepareReviewData_when_preview_falls_back_then_shows_local_totals_and_submits_via_v3() async throws {
        // Given the flag is off, so the preview use case falls back without probing
        let harness = makeHarness(previewResult: nil, flagEnabled: false)
        let preparation = try await harness.adaptor.prepareRefund(for: posOrder())

        // When
        let reviewData = try await harness.adaptor.prepareReviewData(for: posOrder(),
                                                                     preparation: preparation,
                                                                     selectedItems: preparation.selectableItems,
                                                                     reason: nil)

        // Then the review shows the locally calculated totals (unchanged v3 behaviour)
        #expect(reviewData.formattedItemsSubtotal == "$10.00")
        #expect(reviewData.formattedTax == "$1.00")
        #expect(reviewData.formattedRefundTotal == "$11.00")

        // When submitting
        try await harness.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: preparation.selectableItems,
                                               reason: nil)

        // Then the v3 create was dispatched and the v4 create was not
        #expect(harness.spy.dispatchedV3Create == true)
        #expect(harness.service.createRefundLineItems == nil)
    }

    @Test func submitRefund_after_overlapping_previews_uses_latest_server_total() async throws {
        // Given an order with two refundable units and manually-resolved previews, so responses
        // can complete out of order (the regression this pins: a superseded preview must never
        // overwrite the reviewed total that the reader will charge).
        let harness = makeHarness(previewResult: nil, manualPreviewResolution: true, orderQuantity: 2)
        let preparation = try await harness.adaptor.prepareRefund(for: posOrder())
        let selectionA = Array(preparation.selectableItems.prefix(1))
        let selectionB = preparation.selectableItems

        // R1: preparation for selection A, superseded (cancelled) while its request is in flight.
        let taskA = Task { @MainActor in
            try await harness.adaptor.prepareReviewData(for: posOrder(),
                                                        preparation: preparation,
                                                        selectedItems: selectionA,
                                                        reason: nil)
        }
        while harness.service.pendingPreviewCompletions.count < 1 {
            await Task.yield()
        }
        taskA.cancel()

        // R2: preparation for selection B (what the merchant reviews).
        let taskB = Task { @MainActor in
            try await harness.adaptor.prepareReviewData(for: posOrder(),
                                                        preparation: preparation,
                                                        selectedItems: selectionB,
                                                        reason: nil)
        }
        while harness.service.pendingPreviewCompletions.count < 2 {
            await Task.yield()
        }

        // When R2 resolves first ($22) and the cancelled R1 resolves late ($10)
        harness.service.pendingPreviewCompletions[1](.success(preview(total: 22)))
        _ = try await taskB.value
        harness.service.pendingPreviewCompletions[0](.success(preview(total: 10)))
        await #expect(throws: CancellationError.self) {
            _ = try await taskA.value
        }

        // ...and the reviewed (selection B) refund is submitted
        try await harness.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: selectionB,
                                               reason: nil)

        // Then the v4 create carries selection B and the charged amount is the latest server total
        #expect(harness.service.createRefundLineItems?.count == 1)
        #expect(harness.service.createRefundLineItems?.first?.quantity == 2)
        let createEventIndex = try #require(harness.analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.refundCreate.rawValue))
        let amount = harness.analyticsProvider.receivedProperties[createEventIndex]["amount"] as? String
        #expect(amount == "22")
    }

    @Test func prepareReviewData_when_preview_errors_then_throws_refundPreviewFailed() async throws {
        // Given
        let harness = makeHarness(previewResult: .failure(NetworkError.timeout()))
        let preparation = try await harness.adaptor.prepareRefund(for: posOrder())

        // When / Then
        await #expect(throws: POSRefundSubmissionError.refundPreviewFailed) {
            _ = try await harness.adaptor.prepareReviewData(for: posOrder(),
                                                            preparation: preparation,
                                                            selectedItems: preparation.selectableItems,
                                                            reason: nil)
        }
    }
}

private extension POSRefundSubmissionAdaptorTests {

    final class RefundActionSpy {
        var dispatchedV3Create = false
    }

    /// `RefundServiceProtocol` mock pinned to the main actor so the manual-resolution list and the
    /// tests' poll-yield loops stay on one actor (no race between append and count checks).
    @MainActor
    final class MockManualRefundService: RefundServiceProtocol {
        enum MockError: Error {
            case notStubbed
        }

        var previewResult: Result<RefundPreview, Error>?
        var manualPreviewResolution = false
        /// Captured `previewRefund` continuations when the harness uses manual resolution.
        private(set) var pendingPreviewCompletions: [(Result<RefundPreview, Error>) -> Void] = []
        private(set) var createRefundLineItems: [RefundV4LineItem]?
        private(set) var createRefundReason: String?

        func previewRefund(siteID: Int64,
                           orderID: Int64,
                           lineItems: [RefundV4LineItem]) async throws -> RefundPreview {
            if manualPreviewResolution {
                return try await withCheckedThrowingContinuation { continuation in
                    pendingPreviewCompletions.append { result in
                        continuation.resume(with: result)
                    }
                }
            }
            guard let previewResult else {
                throw MockError.notStubbed
            }
            return try previewResult.get()
        }

        func createRefund(siteID: Int64,
                          orderID: Int64,
                          reason: String,
                          automaticRefund: Bool,
                          restockItems: Bool,
                          lineItems: [RefundV4LineItem]) async throws -> Refund {
            createRefundLineItems = lineItems
            createRefundReason = reason
            return .fake()
        }
    }

    struct Harness {
        let adaptor: POSRefundSubmissionAdaptor
        let service: MockManualRefundService
        let spy: RefundActionSpy
        let analyticsProvider: MockAnalyticsProvider
    }

    /// Builds the adaptor with a mocked order service, refund service, stores manager, and a fresh
    /// availability cache. `previewResult` stubs the `RefundService.previewRefund` outcome; pass
    /// `nil` when the preview is not expected to run (e.g. flag off).
    func makeHarness(previewResult: Result<RefundPreview, Error>?,
                     flagEnabled: Bool = true,
                     manualPreviewResolution: Bool = false,
                     orderQuantity: Decimal = 1) -> Harness {
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = "10.9.0"
        let stores = MockStoresManager(sessionManager: session)
        let spy = RefundActionSpy()
        let service = MockManualRefundService()
        service.previewResult = previewResult
        service.manualPreviewResolution = manualPreviewResolution

        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case .createRefund(_, _, let refund, let onCompletion):
                spy.dispatchedV3Create = true
                onCompletion(refund, nil)
            case .retrieveRefund(_, _, _, let onCompletion):
                onCompletion(.fake(), nil)
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case .selectedPaymentGatewayAccount(let onCompletion):
                onCompletion(nil)
            case .loadAccounts(_, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let flags = MockFeatureFlagService()
        flags.isFeatureFlagEnabledReturnValue = [.posRefundsV4: flagEnabled]
        let previewUseCase = POSV4RefundPreviewUseCase(refundService: service,
                                                       stores: stores,
                                                       featureFlagService: flags,
                                                       availabilityCache: V4RefundAvailabilityCache(),
                                                       minimumWooVersion: "10.9.0",
                                                       siteAPILoader: { _ in throw MockManualRefundService.MockError.notStubbed })

        let orderService = MockPOSOrderService()
        orderService.orderToReturn = order(quantity: orderQuantity)

        let analyticsProvider = MockAnalyticsProvider()
        let adaptor = POSRefundSubmissionAdaptor(orderService: orderService,
                                                 refundService: service,
                                                 stores: stores,
                                                 storageManager: MockStorageManager(),
                                                 currencySettings: usdCurrencySettings(),
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                                                 v4RefundPreviewUseCase: previewUseCase)
        return Harness(adaptor: adaptor, service: service, spy: spy, analyticsProvider: analyticsProvider)
    }

    func usdCurrencySettings() -> CurrencySettings {
        CurrencySettings(currencyCode: .USD,
                         currencyPosition: .left,
                         thousandSeparator: ",",
                         decimalSeparator: ".",
                         numberOfDecimals: 2)
    }

    /// Refundable product line(s) at $10.00 + $1.00 tax per unit, no charge, no previous refunds.
    func order(quantity: Decimal = 1) -> Order {
        Order.fake().copy(siteID: siteID,
                          orderID: orderID,
                          currency: "USD",
                          items: [OrderItem.fake().copy(itemID: 10,
                                                        quantity: quantity,
                                                        price: NSDecimalNumber(string: "10"),
                                                        subtotal: "10.00",
                                                        total: "10.00",
                                                        totalTax: "1.00")],
                          refunds: [])
    }

    func posOrder() -> POSOrder {
        POSOrder(id: orderID,
                 number: "\(orderID)",
                 dateCreated: Date(),
                 status: .completed,
                 formattedTotal: "$11.00",
                 formattedSubtotal: "$10.00",
                 paymentMethodID: "woocommerce_payments",
                 paymentMethodTitle: "Card",
                 formattedDiscountTotal: nil,
                 formattedTotalTax: "$1.00",
                 formattedPaymentTotal: "$11.00")
    }

    func preview(total: Decimal = 29.43) -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: total, maxRefundable: 59, breakdown: .fake())
    }
}
