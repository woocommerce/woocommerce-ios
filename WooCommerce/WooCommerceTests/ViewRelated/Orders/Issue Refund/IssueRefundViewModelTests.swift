import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `IssueRefundViewModel`
///
final class IssueRefundViewModelTests: XCTestCase {

    private var analyticsProvider: MockupAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockupAnalyticsProvider()
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
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1, price: 13.50),
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
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1, price: 13.50),
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
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1, price: 13.50),
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
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1, price: 13.50),
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
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1, price: 13.50),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.updateRefundQuantity(quantity: 1, forItemAtIndex: 2)

        // Then
        let selectedItemsTitle = NSLocalizedString("1 item selected", comment: "")
        XCTAssertEqual(viewModel.selectedItemsTitle, selectedItemsTitle)
    }

    func test_viewModel_correctly_calculates_multitple_selected_item_title() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, quantity: 1, price: 13.50),
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
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1, price: 13.50),
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
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, price: 11.50),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2, price: 12.50),
            MockOrderItem.sampleItem(itemID: 3, productID: 3, quantity: 1, price: 13.50),
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
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3, price: 11.50, totalTax: "2.97"),
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

    func test_viewModel_starts_with_next_button_disabled() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
        ]
        let order = MockOrders().makeOrder(items: items)

        // When
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)

        // Then
        XCTAssertFalse(viewModel.isNextButtonEnabled)
    }

    func test_viewModel_next_button_gets_enabled_after_selecting_items() {
        // Given
        let currencySettings = CurrencySettings()
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
        ]
        let order = MockOrders().makeOrder(items: items)
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
            MockOrderItem.sampleItem(itemID: 1, quantity: 3, price: 11.50),
        ]
        let order = MockOrders().makeOrder(items: items)
        let viewModel = IssueRefundViewModel(order: order, refunds: [], currencySettings: currencySettings)
        viewModel.selectAllOrderItems()

        // When
        viewModel.updateRefundQuantity(quantity: 0, forItemAtIndex: 0)

        // Then
        XCTAssertFalse(viewModel.isNextButtonEnabled)
    }

    // MARK: Analytics
    //
    func test_viewModel_tracks_shipping_switch_action_correcly() {
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
}
