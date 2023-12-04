import XCTest
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

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
        let refund = MockRefunds.sampleRefund(shippingLines: [MockRefunds.sampleShippingLine()])

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
        viewModel.updateRefundQuantity(quantity: 2, forItemAtIndex: 1)

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
        let order = MockOrders().makeOrder(items: items)
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // When
        viewModel.updateRefundQuantity(quantity: 2, forItemAtIndex: 0)
        viewModel.updateRefundQuantity(quantity: 1, forItemAtIndex: 1)

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
        viewModel.updateRefundQuantity(quantity: 2, forItemAtIndex: 0)
        XCTAssertEqual(viewModel.title, "$23.00")

        // When
        viewModel.toggleRefundShipping()

        // Then
        // 23.00(current products) + 7.52 (shipping) = 30.62
        XCTAssertEqual(viewModel.title, "$30.62")
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
        viewModel.updateRefundQuantity(quantity: 1, forItemAtIndex: 2)

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
        viewModel.updateRefundQuantity(quantity: 1, forItemAtIndex: 0)

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
        let order = MockOrders().makeOrder(items: items, fees: [])
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
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
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
        viewModel.updateRefundQuantity(quantity: 0, forItemAtIndex: 0)

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
        let order = MockOrders().makeOrder(items: items, fees: [])
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
