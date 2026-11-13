import Testing
import Foundation
import UIKit
import Yosemite
import WooFoundation
import YosemiteTestHelpers
import enum NetworkingCore.DotcomError
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct IssueRefundViewModelServerRefundTests {

    private let siteID: Int64 = 123
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

    // MARK: - Line items

    @Test func serverLineItems_sends_products_by_quantity_and_shipping_and_fees_as_whole_lines() throws {
        // Given
        let selection = makeSelection(items: [refundable(itemID: 1, quantity: 1, total: "36", totalTax: "3.6"),
                                              refundable(itemID: 2, quantity: 0, total: "90", totalTax: "9")],
                                      shippingLines: [shipping(id: 5, total: "10", totalTax: "1")],
                                      fees: [fee(id: 7, total: "5", totalTax: "0.5")])

        // When
        let lines = try #require(IssueRefundViewModel.serverLineItems(for: selection, currencyFormatter: currencyFormatter))

        // Then
        #expect(lines.preview == [.quantityBased(lineItemID: 1, quantity: 1),
                                  .quantityBased(lineItemID: 5, quantity: 1),
                                  .quantityBased(lineItemID: 7, quantity: 1)])
        #expect(lines.create == [.quantityBased(lineItemID: 1, quantity: 1),
                                 .quantityBased(lineItemID: 5, quantity: 1),
                                 .quantityBased(lineItemID: 7, quantity: 1)])
    }

    @Test func serverLineItems_when_shipping_and_fees_are_partially_refunded_or_negative_then_keeps_them_and_drops_zero_lines() throws {
        // Given: remaining amounts as `OrderRefundsOptionsDeterminer` reports them after earlier refunds.
        let selection = makeSelection(items: [],
                                      shippingLines: [shipping(id: 5, total: "4", totalTax: "0.4"),
                                                      shipping(id: 6, total: "0", totalTax: "0")],
                                      fees: [fee(id: 7, total: "2.5", totalTax: "0.25"),
                                             fee(id: 8, total: "-3", totalTax: "-0.3"),
                                             fee(id: 9, total: "0", totalTax: "0")])

        // When
        let lines = try #require(IssueRefundViewModel.serverLineItems(for: selection, currencyFormatter: currencyFormatter))

        // Then
        #expect(lines.preview == [.quantityBased(lineItemID: 5, quantity: 1),
                                  .quantityBased(lineItemID: 7, quantity: 1),
                                  .quantityBased(lineItemID: 8, quantity: 1)])
    }

    @Test func serverLineItems_when_a_selected_product_is_free_then_returns_nil() {
        // Given
        let selection = makeSelection(items: [refundable(itemID: 1, quantity: 1, total: "36", totalTax: "3.6"),
                                              refundable(itemID: 2, quantity: 1, total: "0", totalTax: "0")])

        // When
        let lines = IssueRefundViewModel.serverLineItems(for: selection, currencyFormatter: currencyFormatter)

        // Then
        #expect(lines == nil)
    }

    // MARK: - Confirmation

    @Test func createRefundConfirmationViewModel_when_preview_succeeds_then_shows_preview_total_and_creates_computed_refund_with_pinned_amount() async throws {
        // Given
        let service = MockRefundService()
        service.previewRefundResult = .success(preview(total: 36.3))
        service.createRefundResult = .success(.fake())
        let (sut, stores) = makeSUT(service: service)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: 1)
        sut.toggleRefundShipping()

        // When
        let confirmation = await confirmation(from: sut)
        await submit(confirmation)

        // Then
        #expect(confirmation.refundAmount == "$36.30")
        #expect(service.previewRefundCallCount == 1)
        #expect(try #require(service.spyCreateRefundAmount) == "36.3")
        #expect(!stores.receivedActions.contains { action in
            guard let refundAction = action as? RefundAction, case .createRefund = refundAction else {
                return false
            }
            return true
        })
    }

    @Test func createRefundConfirmationViewModel_when_store_is_below_minimum_version_then_uses_local_total_without_preview() async {
        // Given
        let service = MockRefundService()
        let (sut, _) = makeSUT(service: service, wooVersion: "11.0.9")
        sut.updateRefundQuantity(quantity: 1, forItemWithID: 1)
        sut.toggleRefundShipping()

        // When
        let confirmation = await confirmation(from: sut)

        // Then
        #expect(confirmation.refundAmount == "$30.80")
        #expect(service.previewRefundCallCount == 0)
    }

    @Test func createRefundConfirmationViewModel_when_preview_is_rejected_then_shows_message_and_does_not_navigate() async {
        // Given
        let service = MockRefundService()
        service.previewRefundResult = .failure(DotcomError.unknown(code: "woocommerce_rest_line_item_already_refunded", message: nil, data: nil))
        let (sut, _) = makeSUT(service: service)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: 1)
        var confirmation: RefundConfirmationViewModel?
        var notice: String?
        sut.showRefundPreviewErrorNotice = { notice = $0 }

        // When
        sut.createRefundConfirmationViewModel { confirmation = $0 }
        await waitUntil { notice != nil }

        // Then
        #expect(notice == RefundAPIError.lineItemAlreadyRefunded.localizedDescription)
        #expect(confirmation == nil)
        #expect(sut.isNextButtonEnabled)
    }

    @Test func createRefundConfirmationViewModel_when_selection_changes_during_preview_then_drops_the_result() async {
        // Given
        let service = SuspendedPreviewRefundService()
        let (sut, _) = makeSUT(service: service)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: 1)
        var confirmation: RefundConfirmationViewModel?

        // When
        sut.createRefundConfirmationViewModel { confirmation = $0 }
        await waitUntil { service.isWaiting }
        #expect(sut.isNextButtonAnimating)
        sut.updateRefundQuantity(quantity: 2, forItemWithID: 1)
        service.resume(with: preview(total: 19.8))
        await waitUntil { !sut.isNextButtonAnimating }

        // Then
        #expect(confirmation == nil)
        #expect(sut.isNextButtonEnabled)
    }
}

// MARK: - Helpers

private extension IssueRefundViewModelServerRefundTests {
    /// Order with one taxed product (2 × $18 + 10% tax) and taxed shipping ($10 + $1).
    func makeSUT(service: RefundServiceProtocol, wooVersion: String = "11.3.0") -> (IssueRefundViewModel, MockStoresManager) {
        let session = SessionManager.testingInstance
        session.cachedWooCommerceVersion = wooVersion
        let stores = MockStoresManager(sessionManager: session)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(completion) = action {
                completion(nil)
            }
        }
        // The confirmation reloads the order after a successful refund.
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .retrieveOrder(_, _, completion) = action {
                completion(nil, nil)
            }
        }
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 2, price: 18, total: "36", totalTax: "3.6")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [shipping(id: 5, total: "10", totalTax: "1")], fees: [])
            .copy(siteID: siteID, total: "50.60")
        let cache = ServerRefundAvailabilityCache()
        let previewUseCase = ServerRefundPreviewUseCase(refundService: service,
                                                        flowResolver: RefundFlowResolver(stores: stores,
                                                                                         availabilityCache: cache,
                                                                                         minimumWooVersion: "11.1.0"),
                                                        availabilityCache: cache,
                                                        analytics: WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
                                                        serverFlowUnavailableEvent: nil)
        let sut = IssueRefundViewModel(order: order,
                                       refunds: [],
                                       currencySettings: CurrencySettings(),
                                       stores: stores,
                                       storage: MockStorageManager(),
                                       serverRefunds: ServerRefundDependencies(previewUseCase: previewUseCase, refundService: service))
        return (sut, stores)
    }

    func confirmation(from sut: IssueRefundViewModel) async -> RefundConfirmationViewModel {
        await withCheckedContinuation { continuation in
            sut.createRefundConfirmationViewModel { continuation.resume(returning: $0) }
        }
    }

    func submit(_ confirmation: RefundConfirmationViewModel) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            confirmation.submit(rootViewController: UIViewController(), showInProgressUI: {}) { _ in
                continuation.resume()
            }
        }
    }

    func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<500 where !condition() {
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    func makeSelection(items: [RefundableOrderItem] = [],
                       shippingLines: [ShippingLine] = [],
                       fees: [OrderFeeLine] = []) -> IssueRefundViewModel.RefundSelection {
        IssueRefundViewModel.RefundSelection(items: items,
                                             refundsShipping: shippingLines.isNotEmpty,
                                             shippingLines: shippingLines,
                                             refundsFees: fees.isNotEmpty,
                                             fees: fees,
                                             localTotal: 0)
    }

    func refundable(itemID: Int64, quantity: Int, total: String, totalTax: String) -> RefundableOrderItem {
        RefundableOrderItem(item: MockOrderItem.sampleItem(itemID: itemID, quantity: 2, total: total, totalTax: totalTax), quantity: quantity)
    }

    func shipping(id: Int64, total: String, totalTax: String) -> ShippingLine {
        ShippingLine(shippingID: id, methodTitle: "Flat rate", methodID: "flat_rate", total: total, totalTax: totalTax, taxes: [])
    }

    func fee(id: Int64, total: String, totalTax: String) -> OrderFeeLine {
        OrderFeeLine.fake().copy(feeID: id, total: total, totalTax: totalTax, taxes: [])
    }

    func preview(total: Decimal) -> RefundPreview {
        RefundPreview(subtotal: total, tax: 0, total: total, maxRefundable: 50.6, breakdown: .fake())
    }
}

/// Holds the preview until the test resumes it, so the test can change the selection meanwhile.
private final class SuspendedPreviewRefundService: RefundServiceProtocol, @unchecked Sendable {
    private var continuation: CheckedContinuation<RefundPreview, Error>?

    var isWaiting: Bool {
        continuation != nil
    }

    @MainActor
    func resume(with preview: RefundPreview) {
        continuation?.resume(returning: preview)
        continuation = nil
    }

    @MainActor
    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
        try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      amountOverride: String?,
                      lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        .fake()
    }
}
