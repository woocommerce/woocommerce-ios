import XCTest
import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

import YosemiteTestHelpers
@testable import WooCommerce

/// Test cases for `IssueRefundViewModel`
///
final class IssueRefundViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        super.tearDown()
        analytics = nil
        analyticsProvider = nil
    }


    @MainActor
    func test_quantity_completion_when_selected_item_was_fully_refunded_then_does_not_select_next_item() throws {
        // Given
        let first = MockOrderItem.sampleItem(itemID: 10, productID: 100, quantity: 1, taxes: [], total: "10", totalTax: "0")
        let second = MockOrderItem.sampleItem(itemID: 20, productID: 100, quantity: 3, taxes: [], total: "30", totalTax: "0")
        let order = MockOrders().makeOrder(items: [first, second], shippingLines: [], fees: []).copy(
            total: "40", refunds: [.init(refundID: 1, reason: nil, total: "-10")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        sut.fetch()
        let command = RefundItemQuantityListSelectorCommand(
            maxRefundQuantity: try XCTUnwrap(sut.quantityAvailableForRefundForItemAtIndex(0)),
            currentQuantity: 0, itemID: try XCTUnwrap(sut.itemIDForItemAtIndex(0)))

        // When: history finishes after the picker opened and before its completion.
        try XCTUnwrap(complete)(Refund.fake().copy(items: [
            .init(itemID: 99, refundedItemID: "10", quantity: -1, taxes: [], total: "-10")
        ], shippingLines: [], feeLines: []), nil)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: command.itemID)

        // Then: row zero is now the second order line and must remain unselected.
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 3)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 0)
        XCTAssertFalse(sut.isNextButtonEnabled)
    }

    @MainActor
    func test_quantity_completion_when_an_earlier_item_was_removed_then_selects_original_item() throws {
        // Given
        let first = MockOrderItem.sampleItem(itemID: 10, productID: 100, quantity: 1, taxes: [], total: "10", totalTax: "0")
        let second = MockOrderItem.sampleItem(itemID: 20, productID: 100, quantity: 3, taxes: [], total: "30", totalTax: "0")
        let third = MockOrderItem.sampleItem(itemID: 30, productID: 100, quantity: 5, taxes: [], total: "50", totalTax: "0")
        let order = MockOrders().makeOrder(items: [first, second, third], shippingLines: [], fees: []).copy(
            total: "90", refunds: [.init(refundID: 1, reason: nil, total: "-10")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        sut.fetch()
        let command = RefundItemQuantityListSelectorCommand(
            maxRefundQuantity: try XCTUnwrap(sut.quantityAvailableForRefundForItemAtIndex(1)),
            currentQuantity: 0, itemID: try XCTUnwrap(sut.itemIDForItemAtIndex(1)))

        // When
        try XCTUnwrap(complete)(Refund.fake().copy(items: [
            .init(itemID: 99, refundedItemID: "10", quantity: -1, taxes: [], total: "-10")
        ], shippingLines: [], feeLines: []), nil)
        sut.updateRefundQuantity(quantity: 3, forItemWithID: command.itemID)

        // Then: original line 20 moved to row zero; line 30 must remain unselected.
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 3)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(1), 0)
        XCTAssertEqual(sut.title, "$30.00")
    }

    @MainActor
    func test_quantity_completion_when_available_quantity_was_reduced_then_clamps_to_latest_quantity() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 10, quantity: 3, taxes: [], total: "30", totalTax: "0")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "30", refunds: [.init(refundID: 1, reason: nil, total: "-20")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        sut.fetch()
        let command = RefundItemQuantityListSelectorCommand(
            maxRefundQuantity: try XCTUnwrap(sut.quantityAvailableForRefundForItemAtIndex(0)),
            currentQuantity: 0, itemID: try XCTUnwrap(sut.itemIDForItemAtIndex(0)))

        // When
        try XCTUnwrap(complete)(Refund.fake().copy(items: [
            .init(itemID: 99, refundedItemID: "10", quantity: -2, taxes: [], total: "-20")
        ], shippingLines: [], feeLines: []), nil)
        sut.updateRefundQuantity(quantity: 3, forItemWithID: command.itemID)

        // Then
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 1)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 1)
    }

    func test_fetch_when_retry_is_tapped_twice_then_starts_only_one_refund_batch() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 3, total: "10")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "10", refunds: [.init(refundID: 2, reason: nil, total: "-1")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var completions: [(Refund?, Error?) -> Void] = []
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { completions.append(completion) }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        var retry: (() -> Void)?
        sut.showFetchRefundsErrorNotice = { retry = $0 }
        sut.selectAllOrderItems()
        sut.fetch()
        completions[0](nil, NSError(domain: "test", code: 1))
        let retryAction = try XCTUnwrap(retry)

        // When
        retryAction()
        retryAction()

        // Then
        XCTAssertEqual(completions.count, 2)
        XCTAssertFalse(sut.isNextButtonEnabled)
        XCTAssertTrue(sut.isNextButtonAnimating)
    }


    func test_fetch_when_retry_fails_then_keeps_error_until_later_retry_succeeds() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 3, total: "10")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "10", refunds: [.init(refundID: 2, reason: nil, total: "-1")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var completions: [(Refund?, Error?) -> Void] = []
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { completions.append(completion) }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        var notices = 0
        sut.showFetchRefundsErrorNotice = { _ in notices += 1 }
        sut.selectAllOrderItems()
        sut.fetch()
        completions[0](nil, NSError(domain: "test", code: 1))
        XCTAssertTrue(sut.hasRefundFetchError)

        // When: the first retry also fails.
        sut.retryFetchingRefunds()
        completions[1](nil, NSError(domain: "test", code: 2))

        // Then: Retry remains available and refund confirmation stays blocked.
        XCTAssertEqual(notices, 2)
        XCTAssertTrue(sut.hasRefundFetchError)
        XCTAssertFalse(sut.isNextButtonEnabled)
        XCTAssertFalse(sut.isNextButtonAnimating)

        // When: the subsequent retry succeeds.
        sut.retryFetchingRefunds()
        completions[2](Refund.fake().copy(items: [.init(itemID: 99, refundedItemID: "1", quantity: -2, taxes: [], total: "-6.66")],
                                         shippingLines: [], feeLines: []), nil)

        // Then
        XCTAssertFalse(sut.hasRefundFetchError)
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertFalse(sut.isNextButtonAnimating)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 1)
    }

    func test_sections_when_shipping_refund_has_new_id_then_original_shipping_is_not_offered() throws {
        for metadata in [#"[{"id":1,"key":"_refunded_item_id","value":1}]"#,
                         #"{"0":{"id":1,"key":"_refunded_item_id","value":1}}"#] {
            // Given
            let original = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "5", totalTax: "0.25", taxes: [])
            let refunded = try JSONDecoder().decode(ShippingLine.self, from: Data("""
                {"id":99,"method_title":"Standard","method_id":"standard","total":"-5","total_tax":"-0.25","taxes":[],
                 "meta_data":\(metadata)}
                """.utf8))
            let order = MockOrders().makeOrder(shippingLines: [original])
            // When
            let sut = IssueRefundViewModel(order: order, refunds: [MockRefunds.sampleRefund(shippingLines: [refunded])],
                                           currencySettings: CurrencySettings())
            // Then
            XCTAssertFalse(sut.sections.flatMap(\.rows).contains { $0 is IssueRefundViewModel.ShippingSwitchViewModel })
            XCTAssertEqual(refunded.refundedItemID, 1)
            XCTAssertEqual(refunded.copy().refundedItemID, 1)
        }
    }

    func test_shipping_when_negative_line_is_partially_refunded_then_preserves_remaining_discount() {
        // Given
        let shipping = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "100", totalTax: "0", taxes: [])
        let discount = shipping.copy(shippingID: 2, methodTitle: "Discount", total: "-20")
        let refunded = discount.copy(shippingID: 99, total: "5", refundedItemID: .some(2))
        let item = MockOrderItem.sampleItem(itemID: 3, quantity: 1, total: "100")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [shipping, discount], fees: []).copy(
            total: "180", refunds: [OrderRefundCondensed(refundID: 10, reason: "", total: "-10")])
        let history = Refund.fake().copy(amount: "10", shippingLines: [refunded], feeLines: [])
        let sut = IssueRefundViewModel(order: order, refunds: [history], currencySettings: CurrencySettings())

        // When
        sut.toggleRefundShipping()

        // Then
        XCTAssertEqual(sut.title, "$85.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
        let shippingRows = sut.sections.flatMap(\.rows).compactMap { $0 as? RefundShippingDetailsViewModel }
        XCTAssertEqual(shippingRows.map(\.carrierRate), ["Standard", "Discount"])
    }

    @MainActor
    func test_next_when_paid_selection_rounds_to_zero_then_blocks_until_a_minor_unit_is_selected() {
        for (scale, zero, positive) in [(0, "$0", "$1"), (2, "$0.00", "$0.01"), (3, "$0.000", "$0.001")] {
            // Given
            let settings = CurrencySettings()
            settings.fractionDigits = scale
            let unit = Decimal(sign: .plus, exponent: -scale, significand: 1)
            let tax = "\(unit * Decimal(4) / 10)"
            let items = [1, 2, 3].map { id in
                MockOrderItem.sampleItem(itemID: Int64(id), quantity: 1,
                                         taxes: [.init(taxID: 1, subtotal: "", total: tax)], total: "1", totalTax: "0")
            }
            let history = Refund.fake().copy(amount: "3", items: items.map { item in
                .fake().copy(refundedItemID: .some("\(item.itemID)"), quantity: 0, taxes: [], total: "-1", totalTax: "0")
            }, shippingLines: [], feeLines: [])
            let order = MockOrders().makeOrder(items: items, shippingLines: [], fees: []).copy(
                total: "\(3 + unit)", refunds: [.init(refundID: 1, reason: nil, total: "-3")])
            let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
            stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .selectedPaymentGatewayAccount(completion) = action { completion(nil) }
            }
            var submitted: Refund?
            stores.whenReceivingAction(ofType: RefundAction.self) { action in
                if case let .createRefund(_, _, refund, _) = action { submitted = refund }
            }
            let sut = IssueRefundViewModel(order: order, refunds: [history], currencySettings: settings, stores: stores, storage: storageManager)

            // When
            sut.updateRefundQuantity(quantity: 1, forItemWithID: items[0].itemID)

            // Then
            XCTAssertEqual(sut.title, zero)
            XCTAssertFalse(sut.isNextButtonEnabled)
            sut.updateRefundQuantity(quantity: 1, forItemWithID: items[1].itemID)
            XCTAssertEqual(sut.title, positive)
            XCTAssertTrue(sut.isNextButtonEnabled)
            var confirmation: RefundConfirmationViewModel?
            sut.createRefundConfirmationViewModel { confirmation = $0 }
            XCTAssertEqual(confirmation?.refundAmount, positive)
            confirmation?.submit(rootViewController: UIViewController(), showInProgressUI: {}, onCompletion: { _ in })
            XCTAssertEqual(Decimal(string: submitted?.amount ?? ""), unit)
            XCTAssertEqual(submitted?.items.map(\.quantity), [1, 1])
            XCTAssertEqual(submitted?.items.map(\.total), ["0", "0"])
        }
    }

    func test_shipping_when_only_amount_rounding_is_needed_then_keeps_missing_rate_tax_display() throws {
        // Given
        let shipping = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "0.10", totalTax: "0.006", taxes: [])
        let item = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "100")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [shipping], fees: []).copy(total: "100.11")
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings())

        // When
        sut.toggleRefundShipping()

        // Then
        XCTAssertEqual(sut.title, "$0.11")
        let row = try XCTUnwrap(sut.sections.flatMap(\.rows).compactMap { $0 as? RefundShippingDetailsViewModel }.first)
        XCTAssertEqual(row.shippingTax, "$0.01")
        XCTAssertEqual(row.shippingTotal, "$0.11")
    }

    func test_selection_when_only_subcent_tax_rates_remain_then_summary_uses_zero_money_lines() {
        // Given
        let items = [1, 2, 3].map { id in
            MockOrderItem.sampleItem(itemID: Int64(id), quantity: 1,
                                     taxes: [.init(taxID: 1, subtotal: "", total: "0.004")], total: "0.08", totalTax: "0")
        }
        let history = Refund.fake().copy(amount: "0.24", items: items.map { item in
            .fake().copy(refundedItemID: .some("\(item.itemID)"), quantity: 0, taxes: [], total: "-0.08", totalTax: "0")
        }, shippingLines: [], feeLines: [])
        let order = MockOrders().makeOrder(items: items, shippingLines: [], fees: []).copy(
            total: "0.25", refunds: [OrderRefundCondensed(refundID: 10, reason: "", total: "-0.24")])
        let sut = IssueRefundViewModel(order: order, refunds: [history], currencySettings: CurrencySettings())

        // When
        sut.selectAllOrderItems()

        // Then
        XCTAssertEqual(sut.title, "$0.01")
        XCTAssertTrue(sut.isNextButtonEnabled)
        let summary = sut.sections.flatMap(\.rows).compactMap { $0 as? RefundProductsTotalViewModel }.first
        XCTAssertEqual(summary?.productsTotal, "$0.00")
    }

    func test_sections_when_fee_already_refunded_then_custom_amount_is_not_offered() {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: 1, total: "2", totalTax: "0.10", taxes: [])
        let refunded = fee.copy(feeID: 99, total: "-2", totalTax: "-0.10", refundedItemID: .some(1))
        let order = MockOrders().makeOrder(items: [], shippingLines: [], fees: [fee])
        // When
        let sut = IssueRefundViewModel(order: order, refunds: [Refund.fake().copy(feeLines: [refunded])], currencySettings: CurrencySettings())
        // Then
        XCTAssertFalse(sut.sections.flatMap(\.rows).contains { $0 is IssueRefundViewModel.CustomAmountsSwitchViewModel })
        XCTAssertFalse(sut.isNextButtonEnabled)
    }


    func test_fetch_when_only_negative_shipping_remains_then_clears_hidden_shipping_selection() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 3, quantity: 3, total: "30")
        let shipping = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "10", totalTax: "0", taxes: [])
        let discount = shipping.copy(shippingID: 2, methodTitle: "Discount", total: "-3")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [shipping, discount], fees: []).copy(
            total: "37", refunds: [.init(refundID: 1, reason: nil, total: "-9")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: item.itemID)
        sut.toggleRefundShipping()
        sut.fetch()
        let history = Refund.fake().copy(items: [], shippingLines: [
            shipping.copy(shippingID: 98, total: "-10", refundedItemID: .some(1)),
            discount.copy(shippingID: 99, total: "1", refundedItemID: .some(2))
        ], feeLines: [])

        // When
        try XCTUnwrap(complete)(history, nil)

        // Then
        XCTAssertFalse(sut.sections.flatMap(\.rows).contains { $0 is IssueRefundViewModel.ShippingSwitchViewModel })
        XCTAssertEqual(sut.title, "$10.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
    }

    func test_fetch_when_history_completes_then_publishes_one_consistent_state() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 3, total: "30")
        let shipping = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "5", totalTax: "0", taxes: [])
        let fee = OrderFeeLine.fake().copy(feeID: 2, total: "2", totalTax: "0", taxes: [])
        let order = MockOrders().makeOrder(items: [item], shippingLines: [shipping], fees: [fee]).copy(
            total: "37", refunds: [.init(refundID: 1, reason: nil, total: "-27")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        sut.selectAllOrderItems()
        sut.toggleRefundShipping()
        sut.toggleRefundCustomAmounts()
        sut.fetch()
        var updates = 0
        sut.onChange = { updates += 1 }
        let refund = Refund.fake().copy(items: [.init(itemID: 99, refundedItemID: "1", quantity: -2, taxes: [], total: "-20")],
                                       shippingLines: [shipping.copy(shippingID: 99, total: "-5", refundedItemID: .some(1))],
                                       feeLines: [fee.copy(feeID: 99, total: "-2", refundedItemID: .some(2))])

        // When
        try XCTUnwrap(complete)(refund, nil)

        // Then
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 1)
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 1)
        XCTAssertEqual(sut.title, "$10.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertFalse(sut.isNextButtonAnimating)
        XCTAssertFalse(sut.sections.flatMap(\.rows).contains { $0 is IssueRefundViewModel.ShippingSwitchViewModel })
        XCTAssertFalse(sut.sections.flatMap(\.rows).contains { $0 is IssueRefundViewModel.CustomAmountsSwitchViewModel })
    }

    func test_fetch_when_history_is_loading_or_failed_then_blocks_next_and_can_retry() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 3, total: "10")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "10", refunds: [.init(refundID: 2, reason: nil, total: "-1")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var complete: ((Refund?, Error?) -> Void)?
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { complete = completion }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        var retry: (() -> Void)?
        sut.showFetchRefundsErrorNotice = { retry = $0 }
        sut.selectAllOrderItems()
        // When / Then
        sut.fetch()
        XCTAssertFalse(sut.isNextButtonEnabled)
        XCTAssertTrue(sut.isNextButtonAnimating)
        try XCTUnwrap(complete)(nil, NSError(domain: "test", code: 1))
        XCTAssertFalse(sut.isNextButtonEnabled)
        XCTAssertFalse(sut.isNextButtonAnimating)
        try XCTUnwrap(retry)()
        try XCTUnwrap(complete)(Refund.fake().copy(items: [.init(itemID: 99, refundedItemID: "1", quantity: -2, taxes: [], total: "-6.66")],
                                                    shippingLines: [], feeLines: []), nil)
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.currentQuantityForItemAtIndex(0), 1)
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 1)
    }


    func test_fetch_when_refund_was_deleted_then_removes_stale_id_and_updates_confirmation() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1, taxes: [], total: "100", totalTax: "0")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "100", refunds: [.init(refundID: 1, reason: nil, total: "-40"), .init(refundID: 2, reason: nil, total: "-20")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var completions: [Int64: (Refund?, Error?) -> Void] = [:]
        var requestedIDs: [Int64] = []
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, refundID, completion) = action {
                requestedIDs.append(refundID)
                completions[refundID] = completion
            }
        }
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(completion) = action { completion(nil) }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        let valid = Refund.fake().copy(refundID: 2, amount: "20", items: [], shippingLines: [], feeLines: [])
        var retry: (() -> Void)?
        sut.showFetchRefundsErrorNotice = { retry = $0 }
        sut.selectAllOrderItems()
        // When
        sut.fetch()
        try XCTUnwrap(completions[1])(nil, NetworkRequestError.notFound())
        XCTAssertFalse(sut.isNextButtonEnabled)
        try XCTUnwrap(completions[2])(valid, nil)
        // Then
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.title, "$80.00")
        XCTAssertNil(retry)
        var confirmation: RefundConfirmationViewModel?
        sut.createRefundConfirmationViewModel { confirmation = $0 }
        let row = try XCTUnwrap(confirmation?.sections.first?.rows.first as? RefundConfirmationViewModel.TwoColumnRow)
        XCTAssertEqual(row.value, "$20.00")
        sut.fetch()
        XCTAssertEqual(requestedIDs, [1, 2, 2])
        try XCTUnwrap(completions[2])(valid, nil)
    }

    func test_fetch_when_all_refunds_were_deleted_then_restores_money_and_quantity() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 2, taxes: [], total: "100", totalTax: "0")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "100", refunds: [.init(refundID: 1, reason: nil, total: "-40")])
        let cached = Refund.fake().copy(refundID: 1, amount: "40", items: [.init(itemID: 99, refundedItemID: "1", quantity: -1, taxes: [], total: "-40")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, _, completion) = action { completion(nil, NetworkRequestError.notFound()) }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [cached], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 1)
        // When
        sut.fetch()
        sut.selectAllOrderItems()
        // Then
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.quantityAvailableForRefundForItemAtIndex(0), 2)
        XCTAssertEqual(sut.title, "$100.00")
    }

    func test_fetch_when_missing_refund_and_other_error_then_keeps_history_until_retry_succeeds() throws {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1, taxes: [], total: "100", totalTax: "0")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(
            total: "100", refunds: [.init(refundID: 1, reason: nil, total: "-40"), .init(refundID: 2, reason: nil, total: "-20")])
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        var completions: [Int64: (Refund?, Error?) -> Void] = [:]
        var requestedIDs: [Int64] = []
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .retrieveRefund(_, _, refundID, completion) = action {
                requestedIDs.append(refundID)
                completions[refundID] = completion
            }
        }
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        var retry: (() -> Void)?
        sut.showFetchRefundsErrorNotice = { retry = $0 }
        sut.selectAllOrderItems()
        // When
        sut.fetch()
        try XCTUnwrap(completions[1])(nil, NetworkRequestError.notFound())
        try XCTUnwrap(completions[2])(nil, NSError(domain: "test", code: 1))
        // Then
        XCTAssertFalse(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.title, "$40.00")
        try XCTUnwrap(retry)()
        XCTAssertEqual(requestedIDs, [1, 2, 1, 2])
        try XCTUnwrap(completions[1])(nil, NetworkRequestError.notFound())
        try XCTUnwrap(completions[2])(Refund.fake().copy(refundID: 2, amount: "20", items: [], shippingLines: [], feeLines: []), nil)
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.title, "$80.00")
    }

    func test_selection_when_product_has_negative_price_then_refund_amount_includes_discount() {
        // Given
        let paid = MockOrderItem.sampleItem(itemID: 1, quantity: 1, total: "100")
        let discount = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "-20")
        let other = MockOrderItem.sampleItem(itemID: 3, quantity: 1, total: "100")
        let order = MockOrders().makeOrder(items: [paid, discount, other], shippingLines: [], fees: []).copy(total: "180")
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings())

        // When
        sut.updateRefundQuantity(quantity: 1, forItemWithID: paid.itemID)
        sut.updateRefundQuantity(quantity: 1, forItemWithID: discount.itemID)

        // Then
        XCTAssertEqual(sut.title, "$80.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
        let summary = sut.sections.flatMap(\.rows).compactMap { $0 as? RefundProductsTotalViewModel }.first
        XCTAssertEqual(summary?.productsTotal, "$80.00")
    }

    func test_next_when_only_free_product_is_selected_then_allows_quantity_refund() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1, total: "0")
        let order = MockOrders().makeOrder(items: [item], shippingLines: [], fees: []).copy(total: "0")
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings())
        // When
        sut.selectAllOrderItems()
        // Then
        XCTAssertTrue(sut.isNextButtonEnabled)
        XCTAssertEqual(sut.title, "$0.00")
    }

    func test_next_when_paid_line_is_fully_refunded_by_amount_then_blocks_zero_refund() {
        // Given
        let paid = MockOrderItem.sampleItem(itemID: 1, quantity: 2, total: "200")
        let other = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "10")
        let free = MockOrderItem.sampleItem(itemID: 3, quantity: 1, total: "0")
        let order = MockOrders().makeOrder(items: [paid, other, free], shippingLines: [], fees: []).copy(
            total: "210", refunds: [.init(refundID: 1, reason: nil, total: "-200")])
        let refund = Refund.fake().copy(amount: "200", items: [
            .init(itemID: 99, refundedItemID: "1", quantity: 0, taxes: [], total: "-200")
        ], shippingLines: [], feeLines: [])
        let sut = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: CurrencySettings())

        // When
        sut.updateRefundQuantity(quantity: 2, forItemWithID: paid.itemID)

        // Then
        XCTAssertEqual(sut.title, "$0.00")
        XCTAssertFalse(sut.isNextButtonEnabled)

        // When
        sut.updateRefundQuantity(quantity: 1, forItemWithID: free.itemID)

        // Then
        XCTAssertEqual(sut.title, "$0.00")
        XCTAssertFalse(sut.isNextButtonEnabled)

        // When
        sut.updateRefundQuantity(quantity: 1, forItemWithID: other.itemID)

        // Then
        XCTAssertEqual(sut.title, "$10.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
    }

    func test_next_when_selected_product_is_free_after_discount_then_ignores_unselected_paid_product() {
        // Given
        let free = MockOrderItem.sampleItem(itemID: 1, quantity: 1, subtotal: "100", total: "0")
        let paid = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "10")
        let order = MockOrders().makeOrder(items: [free, paid], shippingLines: [], fees: []).copy(total: "10")
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings())

        // When
        sut.updateRefundQuantity(quantity: 1, forItemWithID: free.itemID)

        // Then
        XCTAssertEqual(sut.title, "$0.00")
        XCTAssertTrue(sut.isNextButtonEnabled)
    }

    func test_next_when_product_had_only_tax_and_tax_was_refunded_then_blocks_zero_refund() {
        // Given
        let item = MockOrderItem.sampleItem(itemID: 1, quantity: 1, taxes: [.init(taxID: 1, subtotal: "10", total: "10")],
                                            total: "0", totalTax: "10")
        let paid = MockOrderItem.sampleItem(itemID: 2, quantity: 1, total: "10")
        let order = MockOrders().makeOrder(items: [item, paid], shippingLines: [], fees: []).copy(
            total: "20", refunds: [.init(refundID: 1, reason: nil, total: "-10")])
        let refund = Refund.fake().copy(amount: "10", items: [
            .init(itemID: 99, refundedItemID: "1", quantity: 0, taxes: [.init(taxID: 1, subtotal: "-10", total: "-10")], total: "0")
        ], shippingLines: [], feeLines: [])
        let sut = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: CurrencySettings())

        // When
        sut.updateRefundQuantity(quantity: 1, forItemWithID: item.itemID)

        // Then
        XCTAssertEqual(sut.title, "$0.00")
        XCTAssertFalse(sut.isNextButtonEnabled)
    }

    func test_next_when_free_product_has_offsetting_shipping_and_fee_then_blocks_zero_refund() {
        // Given
        let free = MockOrderItem.sampleItem(itemID: 1, quantity: 1, total: "0")
        let shipping = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "10", totalTax: "0", taxes: [])
        let fee = OrderFeeLine.fake().copy(feeID: 1, total: "-10", totalTax: "0", taxes: [])
        let order = MockOrders().makeOrder(items: [free], shippingLines: [shipping], fees: [fee]).copy(total: "0")
        let sut = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings())

        // When
        sut.selectAllOrderItems()
        sut.toggleRefundShipping()
        sut.toggleRefundCustomAmounts()

        // Then
        XCTAssertEqual(sut.title, "$0.00")
        XCTAssertFalse(sut.isNextButtonEnabled)
    }

    func test_viewModel_does_not_have_shipping_section_on_order_without_shipping() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: [])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        let rows = viewModel.sections.flatMap { $0.rows }
        XCTAssertFalse(rows.isEmpty)
        rows.forEach { viewModel in
            XCTAssertFalse(viewModel is IssueRefundViewModel.ShippingSwitchViewModel)
            XCTAssertFalse(viewModel is RefundShippingDetailsViewModel)
        }
    }

    func test_viewModel_does_not_have_shipping_section_on_order_with_free_shipping() {
        // Given
        let currencySettings = CurrencySettings()
        let shippingLines = MockOrders.sampleShippingLines(cost: "0.0", tax: "0.0")
        let order = MockOrders().makeOrder(shippingLines: shippingLines)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        let rows = viewModel.sections.flatMap { $0.rows }
        XCTAssertFalse(rows.isEmpty)
        rows.forEach { viewModel in
            XCTAssertFalse(viewModel is IssueRefundViewModel.ShippingSwitchViewModel)
            XCTAssertFalse(viewModel is RefundShippingDetailsViewModel)
        }
    }

    func test_viewModel_does_have_shipping_section_on_order_with_shipping() throws {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: MockOrders.sampleShippingLines())

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        let shippingSwitchRow = try XCTUnwrap(viewModel.sections[safe: 1]?.rows[safe: 0])
        XCTAssertTrue(shippingSwitchRow is IssueRefundViewModel.ShippingSwitchViewModel)
    }

    func test_viewModel_does_not_have_shipping_section_on_order_with_shipping_refunds() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: MockOrders.sampleShippingLines())
        let refund = MockRefunds.sampleRefund(shippingLines: order.shippingLines)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // Then
        let rows = viewModel.sections.flatMap { $0.rows }
        XCTAssertFalse(rows.isEmpty)
        rows.forEach { viewModel in
            XCTAssertFalse(viewModel is IssueRefundViewModel.ShippingSwitchViewModel)
            XCTAssertFalse(viewModel is RefundShippingDetailsViewModel)
        }
    }

    func test_viewModel_does_not_have_shipping_section_on_order_with_unknown_shipping_refund_information() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: MockOrders.sampleShippingLines())
        let refund = MockRefunds.sampleRefund(shippingLines: nil)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // Then
        let rows = viewModel.sections.flatMap { $0.rows }
        XCTAssertFalse(rows.isEmpty)
        rows.forEach { viewModel in
            XCTAssertFalse(viewModel is IssueRefundViewModel.ShippingSwitchViewModel)
            XCTAssertFalse(viewModel is RefundShippingDetailsViewModel)
        }
    }

    func test_viewModel_inserts_shipping_details_after_toggling_switch() throws {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: MockOrders.sampleShippingLines())
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        XCTAssertNil(viewModel.sections[safe: 1]?.rows[safe: 1]) // No shipping details

        // When
        viewModel.toggleRefundShipping()

        // Then
        let shippingDetailsRow = try XCTUnwrap(viewModel.sections[safe: 1]?.rows[safe: 1])
        XCTAssertTrue(shippingDetailsRow is RefundShippingDetailsViewModel)
    }

    func test_viewModel_inserts_shipping_details_for_all_shipping_lines_after_toggling_switch() {
        // Given
        let currencySettings = CurrencySettings()
        let shippingLines = [
            ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "5.00", totalTax: "0.50", taxes: []),
            ShippingLine(shippingID: 2, methodTitle: "Local delivery", methodID: "local_delivery", total: "3.00", totalTax: "0.30", taxes: [])
        ]
        let order = MockOrders().makeOrder(shippingLines: shippingLines)
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.toggleRefundShipping()

        // Then
        let shippingDetailsRows = viewModel.sections.flatMap { $0.rows }.compactMap { $0 as? RefundShippingDetailsViewModel }
        XCTAssertEqual(shippingDetailsRows.map { $0.carrierRate }, ["Standard", "Local delivery"])
    }

    func test_viewModel_keeps_unrefunded_shipping_line_available_when_another_shipping_line_was_refunded() {
        // Given
        let currencySettings = CurrencySettings()
        let shippingLines = [
            ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "5.00", totalTax: "0.50", taxes: []),
            ShippingLine(shippingID: 2, methodTitle: "Local delivery", methodID: "local_delivery", total: "3.00", totalTax: "0.30", taxes: [])
        ]
        let order = MockOrders().makeOrder(shippingLines: shippingLines)
        let refund = MockRefunds.sampleRefund(shippingLines: [shippingLines[0]])
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // When
        viewModel.toggleRefundShipping()

        // Then
        let shippingDetailsRows = viewModel.sections.flatMap { $0.rows }.compactMap { $0 as? RefundShippingDetailsViewModel }
        XCTAssertEqual(shippingDetailsRows.map { $0.carrierRate }, ["Local delivery"])
        XCTAssertEqual(viewModel.title, "$3.30")
    }

    func test_viewModel_returns_correct_quantity_available_for_refund() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(quantity: 3),
            MockOrderItem.sampleItem(quantity: 2),
            MockOrderItem.sampleItem(quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(0), 3)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(1), 2)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(2), 1)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(3), nil)
    }

    func test_viewModel_returns_0_current_refund_quantity_for_a_clean_order() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(0), 0)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(1), 0)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(2), 0)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(3), nil)
    }

    func test_viewModel_returns_correct_current_refund_quantity_after_updating_an_item() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.updateRefundQuantity(quantity: 2, forItemWithID: items[1].itemID)

        // Then
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(0), 0)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(1), 2)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(2), 0)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(3), nil)
    }

    func test_viewModel_updates_refund_quantities_after_selecting_all() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(0), 3)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(1), 2)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(2), 1)
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(3), nil)
    }

    func test_viewModel_updates_refund_quantities_after_selecting_all_while_having_previous_refunds() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -2),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -2),
        ])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(0), 1) // Product 1
        XCTAssertEqual(viewModel.currentQuantityForItemAtIndex(1), 1) // Product 3 is at index 1 because Product 2 was refunded
    }

    func test_viewModel_correctly_adds_item_selections_to_title() {
        // Given
        let item1Price: NSDecimalNumber = 11.50
        let item1Quantity: Decimal  = 3

        let item2Price: NSDecimalNumber = 12.50
        let item2Quantity: Decimal  = 2

        let item3Price: NSDecimalNumber  = 13.50
        let item3Quantity: Decimal  = 1


        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 1, quantity: item1Quantity, price: item1Price),
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 2, quantity: item2Quantity, price: item2Price),
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 2, quantity: item3Quantity, price: item3Price),
        ]
        let order = MockOrders().makeOrder(items: items).copy(total: "100.00")
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.updateRefundQuantity(quantity: 2, forItemWithID: items[0].itemID)
        viewModel.updateRefundQuantity(quantity: 1, forItemWithID: items[1].itemID)

        // Then
        // 11.50(item 1) x 2 (quantity) = 23.00
        // 12.50(item 2) x 1 (quantity = 12.50
        // Total = 35.50
        XCTAssertEqual(viewModel.title, "$35.50")
    }

    func test_viewModel_correctly_adds_shipping_selection_to_title() {
        // Given
        let item1Price: NSDecimalNumber = 11.50
        let item1Quantity: Decimal  = 3

        let item2Price: NSDecimalNumber = 12.50
        let item2Quantity: Decimal  = 2

        let item3Price: NSDecimalNumber  = 13.50
        let item3Quantity: Decimal  = 1

        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 1, quantity: item1Quantity, price: item1Price),
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 2, quantity: item2Quantity, price: item2Price),
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 2, quantity: item3Quantity, price: item3Price),
        ]
        let shippingLines = MockOrders.sampleShippingLines(cost: "7.00", tax: "0.62")
        let order = MockOrders().makeOrder(items: items, shippingLines: shippingLines)
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // 11.50 (item 1) x 2 (quantity) = 23.0
        viewModel.updateRefundQuantity(quantity: 2, forItemWithID: items[0].itemID)
        XCTAssertEqual(viewModel.title, "$23.00")

        // When
        viewModel.toggleRefundShipping()

        // Then
        // 23.00(current products) + 7.52 (shipping) = 30.62
        XCTAssertEqual(viewModel.title, "$30.62")
    }

    func test_viewModel_correctly_adds_multiple_shipping_lines_to_title() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 1, quantity: 3, price: 11.50)
        ]
        let shippingLines = [
            ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: "7.00", totalTax: "0.62", taxes: []),
            ShippingLine(shippingID: 2, methodTitle: "Local delivery", methodID: "local_delivery", total: "3.00", totalTax: "0.30", taxes: [])
        ]
        let order = MockOrders().makeOrder(items: items, shippingLines: shippingLines).copy(total: "100.00")
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // 11.50 (item 1) x 2 (quantity) = 23.0
        viewModel.updateRefundQuantity(quantity: 2, forItemWithID: items[0].itemID)
        XCTAssertEqual(viewModel.title, "$23.00")

        // When
        viewModel.toggleRefundShipping()

        // Then
        // 23.00(current products) + 7.62 (first shipping) + 3.30 (second shipping) = 33.92
        XCTAssertEqual(viewModel.title, "$33.92")
    }

    func test_viewModel_starts_with_zero_count_label() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        let selectedItemsTitle = String(format: NSLocalizedString("%d items selected", comment: ""), 0)
        XCTAssertEqual(viewModel.selectedItemsTitle, selectedItemsTitle)
    }

    func test_viewModel_correctly_calculates_1_selected_item_title() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.updateRefundQuantity(quantity: 1, forItemWithID: items[2].itemID)

        // Then
        let selectedItemsTitle = NSLocalizedString("1 item selected", comment: "")
        XCTAssertEqual(viewModel.selectedItemsTitle, selectedItemsTitle)
    }

    func test_viewModel_correctly_calculates_multiple_selected_item_title() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.selectAllOrderItems()

        // Then
        let selectedItemsTitle = String(format: NSLocalizedString("%d items selected", comment: ""), 6)
        XCTAssertEqual(viewModel.selectedItemsTitle, selectedItemsTitle)
    }

    func test_viewModel_correctly_reduces_refunded_items() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -2),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -1),
        ])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(0), 1)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(1), 1)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(2), 1)
    }

    func test_viewModel_correctly_filters_items_already_refunded() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1),
        ]
        let order = MockOrders().makeOrder(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -2),
        ])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // Then
        let itemRows = viewModel.sections[0].rows
        XCTAssertEqual(itemRows.count, 2) // One item left + summary row
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(0), 1)
    }

    func test_viewModel_total_is_correctly_calculated_while_having_previous_refunds() {
        // Given
        let item1Price: Decimal = 11.50
        let item1Quantity: Decimal  = 3

        let currencySettings = CurrencySettings()
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let items = [
            MockOrderItem.sampleItem(itemID: 1,
                                     productID: 1,
                                     quantity: item1Quantity,
                                     total: currencyFormatter.localize(item1Price * item1Quantity) ?? "0",
                                     totalTax: "2.97")
        ]
        let order = MockOrders().makeOrder(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -1),
        ])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)
        viewModel.updateRefundQuantity(quantity: 1, forItemWithID: items[0].itemID)

        // Then
        // Price is 11.50 and tax is 0.99 (2.97 / 3(quantity))
        XCTAssertEqual(viewModel.title, "$12.49")
    }

    func test_isNextButtonEnabled_when_shouldRefundCustomAmountsByDefault_is_false_then_returns_false() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [])
        let refundableOrderItemsDeterminer = MockOrderRefundsOptionsDeterminer(shouldRefundCustomAmountsByDefault: false)

        // When
        let viewModel = IssueRefundViewModel(order: order,
                                             refunds: [],
                                             currencySettings: currencySettings,
                                             refundableOrderItemsDeterminer: refundableOrderItemsDeterminer)

        // Then
        XCTAssertFalse(viewModel.isNextButtonEnabled)
    }

    func test_isNextButtonEnabled_when_shouldRefundCustomAmountsByDefault_is_true_then_returns_true() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [.fake().copy(total: "1", totalTax: "0", taxes: [])])
        let refundableOrderItemsDeterminer = MockOrderRefundsOptionsDeterminer(shouldRefundCustomAmountsByDefault: true)

        // When
        let viewModel = IssueRefundViewModel(order: order,
                                             refunds: [],
                                             currencySettings: currencySettings,
                                             refundableOrderItemsDeterminer: refundableOrderItemsDeterminer)

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
    }

    func test_viewModel_next_button_gets_enabled_after_selecting_items() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, total: "30"),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [])
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
    }

    func test_viewModel_next_button_gets_disabled_after_selecting_and_then_unselecting_items() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [])
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.selectAllOrderItems()

        // When
        viewModel.updateRefundQuantity(quantity: 0, forItemWithID: items[0].itemID)

        // Then
        XCTAssertFalse(viewModel.isNextButtonEnabled)
    }

    func test_hasUnsavedChanges_when_shouldRefundCustomAmountsByDefault_is_false_then_returns_false() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [])
        let refundableOrderItemsDeterminer = MockOrderRefundsOptionsDeterminer(shouldRefundCustomAmountsByDefault: false)

        // When
        let viewModel = IssueRefundViewModel(order: order,
                                             refunds: [],
                                             currencySettings: currencySettings,
                                             refundableOrderItemsDeterminer: refundableOrderItemsDeterminer)

        // Then
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    func test_hasUnsavedChanges_when_shouldRefundCustomAmountsByDefault_is_true_then_returns_true() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [.fake().copy(total: "1", totalTax: "0", taxes: [])])
        let refundableOrderItemsDeterminer = MockOrderRefundsOptionsDeterminer(shouldRefundCustomAmountsByDefault: true)

        // When
        let viewModel = IssueRefundViewModel(order: order,
                                             refunds: [],
                                             currencySettings: currencySettings,
                                             refundableOrderItemsDeterminer: refundableOrderItemsDeterminer)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func test_viewModel_unsaved_changes_states_becomes_true_after_selecting_items() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items)
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: Analytics
    //
    func test_viewModel_tracks_shipping_switch_action_correctly() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder()
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings, analytics: analytics)

        // When
        viewModel.toggleRefundShipping()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.createOrderRefundShippingOptionTapped.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["order_id"] as? String, "\(order.orderID)")
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["action"] as? String, "on")
    }

    func test_viewModel_correctly_tracks_when_the_next_button_is_tapped() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder()
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings, analytics: analytics)

        // When
        viewModel.trackNextButtonTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.createOrderRefundNextButtonTapped.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["order_id"] as? String, "\(order.orderID)")
    }

    func test_viewModel_correctly_tracks_when_the_quantity_button_is_tapped() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder()
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings, analytics: analytics)

        // When
        viewModel.trackQuantityButtonTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.createOrderRefundItemQuantityDialogOpened.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["order_id"] as? String, "\(order.orderID)")
    }

    func test_viewModel_correctly_tracks_when_the_sellectAll_button_is_tapped() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder()
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings, analytics: analytics)

        // When
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.createOrderRefundSelectAllItemsButtonTapped.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["order_id"] as? String, "\(order.orderID)")
    }

    func test_viewModel_shows_selectAllButton_if_there_are_items_to_refund() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, totalTax: "2.97"),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        XCTAssertTrue(viewModel.isSelectAllButtonVisible)
    }

    func test_viewModel_hides_selectAllButton_if_there_are_no_items_to_refund() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, totalTax: "2.97"),
        ]
        let order = MockOrders().makeOrder(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(itemID: 1, productID: 1, quantity: -3),
        ])

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [refund], currencySettings: currencySettings)

        // Then
        XCTAssertFalse(viewModel.isSelectAllButtonVisible)
    }

    func test_fetch_when_there_is_a_payment_gateway_stored_then_calls_to_fetch_charge() throws {
        // Given
        // The order has a chargeID
        let order = MockOrders().sampleOrder().copy(chargeID: "ch_id")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        // When
        let chargeFetched: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                guard case let .fetchWCPayCharge(siteID: _, chargeID: "ch_id", onCompletion: onCompletion) = action else {
                    return
                }
                onCompletion(.success(WCPayCharge.fake()))
                promise(true)
            }

            let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: self.storageManager)
            viewModel.fetch()
        }

        // Then
        XCTAssertTrue(chargeFetched)
    }

    func test_fetch_when_fetching_charge_fails_then_it_notifies_it() throws {
        // Given
        var showFetchChargeErrorNotice = false
        // The order has a chargeID
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items).copy(chargeID: "ch_id")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .fetchWCPayCharge(siteID: _, chargeID: _, onCompletion: onCompletion) = action {
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            }
        }

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)
        viewModel.showFetchChargeErrorNotice = { _ in
            showFetchChargeErrorNotice = true
        }
        viewModel.fetch()

        // Then
        XCTAssertTrue(showFetchChargeErrorNotice)
    }

    func test_viewModel_shows_spinner_when_charge_not_fetched_yet() {
        // Given
        // The order has a chargeID
        let order = MockOrders().sampleOrder().copy(chargeID: "ch_id")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)

        // Then
        XCTAssertTrue(viewModel.isNextButtonAnimating)
    }

    func test_viewModel_does_not_show_spinner_when_there_is_no_charge_to_fetch() {
        // Given
        // The order has a chargeID
        let order = MockOrders().sampleOrder().copy(chargeID: nil)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)

        // Then
        XCTAssertFalse(viewModel.isNextButtonAnimating)
    }

    func test_viewModel_does_not_show_spinner_when_there_is_no_charge_to_fetch_but_an_empty_chargeID() {
        // Given
        // The order has a chargeID
        let order = MockOrders().sampleOrder().copy(chargeID: "")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)

        // Then
        XCTAssertFalse(viewModel.isNextButtonAnimating)
    }

    func test_viewModel_hides_spinner_when_charge_found_in_storage() {
        // Given
        // The order has a chargeID
        let order = MockOrders().sampleOrder().copy(chargeID: "ch_id")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: CurrencySettings(), stores: stores, storage: storageManager)

        let charge = storage.insertNewObject(ofType: StorageWCPayCharge.self)
        charge.update(with: WCPayCharge.fake().copy(siteID: order.siteID, id: "ch_id"))
        storage.saveIfNeeded()

        // Then
        XCTAssertFalse(viewModel.isNextButtonAnimating)
    }

    func test_viewModel_title_when_selection_exceeds_remaining_refundable_amount_then_total_is_clamped() {
        // Given
        // An order with 1.00 remaining refundable (2.00 total, 1.00 already refunded) and items
        // whose locally summed refund value (1.50) exceeds it.
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItemWithCalculatedTotal(itemID: 1, quantity: 1, price: 1.50)
        ]
        let previousRefund = OrderRefundCondensed(refundID: 1, reason: nil, total: "-1.00")
        let order = MockOrders().makeOrder(items: items, refunds: [previousRefund]).copy(total: "2.00")
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.selectAllOrderItems()

        // Then
        XCTAssertEqual(viewModel.title, "$1.00")
    }
}

private extension MockOrderItem {
    static func sampleItemWithCalculatedTotal(itemID: Int64,
                                              quantity: Decimal,
                                              price: NSDecimalNumber) -> OrderItem {
        let currencySettings = CurrencySettings()
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        return MockOrderItem.sampleItem(itemID: itemID,
                                        quantity: quantity,
                                        price: price,
                                        total: currencyFormatter.localize((price as Decimal) * quantity) ?? "0")
    }
}
