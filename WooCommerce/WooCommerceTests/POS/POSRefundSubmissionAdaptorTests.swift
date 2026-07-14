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
        #expect(reviewData?.formattedItemsSubtotal == "$27.00")
        #expect(reviewData?.formattedTax == "$2.43")
        #expect(reviewData?.formattedRefundTotal == "$29.43")

        // When submitting
        try await harness.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: preparation.selectableItems,
                                               reason: "Damaged item")

        // Then the simplified v4 create was dispatched instead of the v3 create
        #expect(harness.spy.createRefundV4LineItems?.isEmpty == false)
        #expect(harness.spy.createRefundV4Reason == "Damaged item")
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
        #expect(reviewData?.formattedItemsSubtotal == "$10.00")
        #expect(reviewData?.formattedTax == "$1.00")
        #expect(reviewData?.formattedRefundTotal == "$11.00")

        // When submitting
        try await harness.adaptor.submitRefund(for: posOrder(),
                                               preparation: preparation,
                                               selectedItems: preparation.selectableItems,
                                               reason: nil)

        // Then the v3 create was dispatched and the v4 create was not
        #expect(harness.spy.dispatchedV3Create == true)
        #expect(harness.spy.createRefundV4LineItems == nil)
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
        var createRefundV4LineItems: [RefundV4LineItem]?
        var createRefundV4Reason: String?
        var dispatchedV3Create = false
    }

    struct Harness {
        let adaptor: POSRefundSubmissionAdaptor
        let spy: RefundActionSpy
    }

    /// Builds the adaptor with a mocked order service, stores manager, and a fresh availability
    /// cache. `previewResult` stubs the `RefundAction.previewRefund` outcome; pass `nil` when the
    /// preview is not expected to be dispatched (e.g. flag off).
    func makeHarness(previewResult: Result<RefundPreview, Error>?, flagEnabled: Bool = true) -> Harness {
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = "10.9.0"
        let stores = MockStoresManager(sessionManager: session)
        let spy = RefundActionSpy()

        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case .previewRefund(_, _, _, let onCompletion):
                if let previewResult {
                    onCompletion(previewResult)
                }
            case .createRefundV4(_, _, let reason, _, _, let lineItems, let onCompletion):
                spy.createRefundV4LineItems = lineItems
                spy.createRefundV4Reason = reason
                onCompletion(.success(.fake()))
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
        let previewUseCase = POSV4RefundPreviewUseCase(stores: stores,
                                                       featureFlagService: flags,
                                                       availabilityCache: V4RefundAvailabilityCache(),
                                                       minimumWooVersion: "10.9.0")

        let orderService = MockPOSOrderService()
        orderService.orderToReturn = order()

        let adaptor = POSRefundSubmissionAdaptor(orderService: orderService,
                                                 stores: stores,
                                                 storageManager: MockStorageManager(),
                                                 currencySettings: usdCurrencySettings(),
                                                 analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
                                                 v4RefundPreviewUseCase: previewUseCase)
        return Harness(adaptor: adaptor, spy: spy)
    }

    func usdCurrencySettings() -> CurrencySettings {
        CurrencySettings(currencyCode: .USD,
                         currencyPosition: .left,
                         thousandSeparator: ",",
                         decimalSeparator: ".",
                         numberOfDecimals: 2)
    }

    /// One refundable product line ($10.00 + $1.00 tax), no charge, no previous refunds.
    func order() -> Order {
        Order.fake().copy(siteID: siteID,
                          orderID: orderID,
                          currency: "USD",
                          items: [OrderItem.fake().copy(itemID: 10,
                                                        quantity: 1,
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

    func preview() -> RefundPreview {
        RefundPreview(subtotal: 27, tax: 2.43, total: 29.43, maxRefundable: 59, breakdown: .fake())
    }
}
