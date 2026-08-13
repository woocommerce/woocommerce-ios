import Testing
import Foundation
import Yosemite
import YosemiteTestHelpers
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
import WooFoundation
@testable import PointOfSale
@testable import WooCommerce

/// Covers the server-calculated wire-in seams of `POSRefundSubmissionAdaptor`: review data built
/// from the server-calculated preview vs the local fallback, the preview-failure error, and routing
/// the submission through the server-computed create only when a preview was obtained.
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSRefundSubmissionAdaptorTests {

    private let siteID: Int64 = 123
    private let orderID: Int64 = 560

    @Test func prepareReviewData_when_preview_is_server_calculated_then_shows_server_totals_and_submits_via_computed_create() async throws {
        // Given
        let sut = makeSUT(previewResult: .success(preview()))
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())

        // When
        let reviewData = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                                 preparation: preparation,
                                                                 selectedItems: preparation.selectableItems,
                                                                 reason: nil)

        // Then the review shows the server-calculated totals, not the local math
        #expect(reviewData.formattedItemsSubtotal == "$27.00")
        #expect(reviewData.formattedTax == "$2.43")
        #expect(reviewData.formattedRefundTotal == "$29.43")

        // When submitting
        try await sut.adaptor.submitRefund(for: posOrder(),
                                           preparation: preparation,
                                           selectedItems: preparation.selectableItems,
                                           reason: "Damaged item")

        // Then the server-computed create was dispatched instead of the classic v3 create
        #expect(sut.service.createRefundLineItems?.isEmpty == false)
        #expect(sut.service.createRefundReason == "Damaged item")
        #expect(sut.spy.dispatchedClassicCreate == false)
    }

    @Test func prepareReviewData_when_preview_falls_back_then_shows_local_totals_and_submits_via_classic_create() async throws {
        // Given the flag is off, so the preview use case falls back without probing
        let sut = makeSUT(previewResult: nil, flagEnabled: false)
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())

        // When
        let reviewData = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                                 preparation: preparation,
                                                                 selectedItems: preparation.selectableItems,
                                                                 reason: nil)

        // Then the review shows the locally calculated totals (unchanged classic behaviour)
        #expect(reviewData.formattedItemsSubtotal == "$10.00")
        #expect(reviewData.formattedTax == "$1.00")
        #expect(reviewData.formattedRefundTotal == "$11.00")

        // When submitting
        try await sut.adaptor.submitRefund(for: posOrder(),
                                           preparation: preparation,
                                           selectedItems: preparation.selectableItems,
                                           reason: nil)

        // Then the classic v3 create was dispatched and the computed create was not
        #expect(sut.spy.dispatchedClassicCreate == true)
        #expect(sut.service.createRefundLineItems == nil)
    }

    @Test func submitRefund_after_overlapping_previews_uses_latest_server_total() async throws {
        // Given an order with two refundable units and manually-resolved previews, so responses
        // can complete out of order (the regression this pins: a superseded preview must never
        // overwrite the reviewed total that the reader will charge).
        let sut = makeSUT(previewResult: nil, manualPreviewResolution: true, orderQuantity: 2)
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())
        let selectionA = Array(preparation.selectableItems.prefix(1))
        let selectionB = preparation.selectableItems

        // R1: preparation for selection A, superseded (cancelled) while its request is in flight.
        let taskA = Task { @MainActor in
            try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: selectionA,
                                                    reason: nil)
        }
        while sut.service.pendingPreviewCompletions.count < 1 {
            await Task.yield()
        }
        taskA.cancel()

        // R2: preparation for selection B (what the merchant reviews).
        let taskB = Task { @MainActor in
            try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: selectionB,
                                                    reason: nil)
        }
        while sut.service.pendingPreviewCompletions.count < 2 {
            await Task.yield()
        }

        // When R2 resolves first ($22) and the cancelled R1 resolves late ($10)
        sut.service.pendingPreviewCompletions[1](.success(preview(total: 22)))
        _ = try await taskB.value
        sut.service.pendingPreviewCompletions[0](.success(preview(total: 10)))
        await #expect(throws: CancellationError.self) {
            _ = try await taskA.value
        }

        // ...and the reviewed (selection B) refund is submitted
        try await sut.adaptor.submitRefund(for: posOrder(),
                                           preparation: preparation,
                                           selectedItems: selectionB,
                                           reason: nil)

        // Then the computed create carries selection B and the charged amount is the latest server total
        #expect(sut.service.createRefundLineItems?.count == 1)
        #expect(sut.service.createRefundLineItems?.first?.quantity == 2)
        let createEventIndex = try #require(sut.analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.refundCreate.rawValue))
        let amount = sut.analyticsProvider.receivedProperties[createEventIndex]["amount"] as? String
        #expect(amount == "22")
    }

    @Test func submitRefund_when_uncancelled_previews_resolve_out_of_order_uses_the_reviewed_total() async throws {
        // Given two previews in flight for different selections and neither cancelled, so both
        // write their result. Totals are stored per selection, so the order in which they land
        // cannot change what a given selection submits.
        let sut = makeSUT(previewResult: nil, manualPreviewResolution: true, orderQuantity: 2)
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())
        let selectionA = Array(preparation.selectableItems.prefix(1))
        let selectionB = preparation.selectableItems

        let taskA = Task { @MainActor in
            try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: selectionA,
                                                    reason: nil)
        }
        while sut.service.pendingPreviewCompletions.count < 1 {
            await Task.yield()
        }

        let taskB = Task { @MainActor in
            try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: selectionB,
                                                    reason: nil)
        }
        while sut.service.pendingPreviewCompletions.count < 2 {
            await Task.yield()
        }

        // When selection B resolves first ($22, the reviewed selection) and selection A resolves
        // afterwards ($10)
        sut.service.pendingPreviewCompletions[1](.success(preview(total: 22)))
        _ = try await taskB.value
        sut.service.pendingPreviewCompletions[0](.success(preview(total: 10)))
        _ = try await taskA.value

        try await sut.adaptor.submitRefund(for: posOrder(),
                                           preparation: preparation,
                                           selectedItems: selectionB,
                                           reason: nil)

        // Then selection B is charged its own server total, not the late arrival's
        #expect(sut.service.createRefundLineItems?.count == 1)
        #expect(sut.service.createRefundLineItems?.first?.quantity == 2)
        let createEventIndex = try #require(sut.analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.refundCreate.rawValue))
        let amount = sut.analyticsProvider.receivedProperties[createEventIndex]["amount"] as? String
        #expect(amount == "22")
    }

    @Test func submitRefund_when_a_previewed_selection_falls_back_then_the_classic_create_is_used() async throws {
        // Given a selection previewed successfully, then previewed again with the server flow no
        // longer available (the clearing side of the ghost-refund invariant).
        let sut = makeSUT(previewResult: .success(preview(total: 22)))
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())
        _ = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: preparation.selectableItems,
                                                    reason: nil)

        // When the same selection is re-previewed and the site now reports the local fallback
        sut.flags.isFeatureFlagEnabledReturnValue = [.posServerCalculatedRefunds: false]
        _ = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: preparation.selectableItems,
                                                    reason: nil)
        try await sut.adaptor.submitRefund(for: posOrder(),
                                           preparation: preparation,
                                           selectedItems: preparation.selectableItems,
                                           reason: nil)

        // Then no computed create is sent: the stale server total was cleared for that selection.
        #expect(sut.service.createRefundLineItems == nil)
    }

    @Test func prepareReviewData_when_preview_errors_then_throws_refundPreviewFailed() async throws {
        // Given
        let sut = makeSUT(previewResult: .failure(NetworkError.timeout()))
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())

        // When / Then
        await #expect(throws: POSRefundSubmissionError.refundPreviewFailed) {
            _ = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                        preparation: preparation,
                                                        selectedItems: preparation.selectableItems,
                                                        reason: nil)
        }
    }

    @Test func prepareReviewData_when_preview_rejected_with_mapped_code_then_throws_typed_rejection() async throws {
        // Given the server rejects the selection with an actionable code
        let error = DotcomError.unknown(code: "woocommerce_rest_line_item_already_refunded", message: nil, data: nil)
        let sut = makeSUT(previewResult: .failure(error))
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())

        // When / Then the typed rejection (with its cashier-facing copy) surfaces instead of the blanket failure
        await #expect(throws: RefundAPIError.lineItemAlreadyRefunded) {
            _ = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                        preparation: preparation,
                                                        selectedItems: preparation.selectableItems,
                                                        reason: nil)
        }
    }

    @Test func submitRefund_when_computed_create_rejected_with_mapped_code_then_throws_typed_rejection() async throws {
        // Given a successful preview (so the server-computed create path is used) and a create
        // that the server rejects because the order changed in the meantime
        let sut = makeSUT(previewResult: .success(preview()))
        sut.service.createRefundError = DotcomError.unknown(code: "woocommerce_rest_refund_exceeds_remaining", message: nil, data: nil)
        let preparation = try await sut.adaptor.prepareRefund(for: posOrder())
        _ = try await sut.adaptor.prepareReviewData(for: posOrder(),
                                                    preparation: preparation,
                                                    selectedItems: preparation.selectableItems,
                                                    reason: nil)

        // When / Then
        await #expect(throws: RefundAPIError.refundExceedsRemaining) {
            try await sut.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: preparation.selectableItems,
                                               reason: nil)
        }
    }
}

private extension POSRefundSubmissionAdaptorTests {

    final class RefundActionSpy {
        var dispatchedClassicCreate = false
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
        var createRefundError: Error?
        /// Captured `previewRefund` continuations when the test uses manual resolution.
        private(set) var pendingPreviewCompletions: [(Result<RefundPreview, Error>) -> Void] = []
        private(set) var createRefundLineItems: [ComputedRefundLineItem]?
        private(set) var createRefundReason: String?

        func previewRefund(siteID: Int64,
                           orderID: Int64,
                           lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
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
                          amountOverride: String?,
                          lineItems: [ComputedRefundLineItem]) async throws -> Refund {
            createRefundLineItems = lineItems
            createRefundReason = reason
            if let createRefundError {
                throw createRefundError
            }
            return .fake()
        }
    }

    struct SUT {
        let adaptor: POSRefundSubmissionAdaptor
        let service: MockManualRefundService
        let spy: RefundActionSpy
        let analyticsProvider: MockAnalyticsProvider
        /// Exposed so a test can change eligibility between two previews of the same selection.
        let flags: MockFeatureFlagService
    }

    /// Builds the adaptor with a mocked order service, refund service, stores manager, and a fresh
    /// availability cache. `previewResult` stubs the `RefundService.previewRefund` outcome; pass
    /// `nil` when the preview is not expected to run (e.g. flag off).
    func makeSUT(previewResult: Result<RefundPreview, Error>?,
                     flagEnabled: Bool = true,
                     manualPreviewResolution: Bool = false,
                     orderQuantity: Decimal = 1) -> SUT {
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = "11.1.0"
        let stores = MockStoresManager(sessionManager: session)
        let spy = RefundActionSpy()
        let service = MockManualRefundService()
        service.previewResult = previewResult
        service.manualPreviewResolution = manualPreviewResolution

        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case .createRefund(_, _, let refund, let onCompletion):
                spy.dispatchedClassicCreate = true
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
        flags.isFeatureFlagEnabledReturnValue = [.posServerCalculatedRefunds: flagEnabled]
        let availabilityCache = ServerRefundAvailabilityCache()
        let previewUseCase = POSServerRefundPreviewUseCase(refundService: service,
                                                           flowResolver: POSRefundFlowResolver(stores: stores,
                                                                                               featureFlagService: flags,
                                                                                               availabilityCache: availabilityCache,
                                                                                               minimumWooVersion: "11.1.0"),
                                                           availabilityCache: availabilityCache)

        let orderService = MockPOSOrderService()
        orderService.orderToReturn = order(quantity: orderQuantity)

        let analyticsProvider = MockAnalyticsProvider()
        let adaptor = POSRefundSubmissionAdaptor(orderService: orderService,
                                                 refundService: service,
                                                 stores: stores,
                                                 storageManager: MockStorageManager(),
                                                 currencySettings: usdCurrencySettings(),
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                                                 serverRefundPreviewUseCase: previewUseCase)
        return SUT(adaptor: adaptor,
                   service: service,
                   spy: spy,
                   analyticsProvider: analyticsProvider,
                   flags: flags)
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
