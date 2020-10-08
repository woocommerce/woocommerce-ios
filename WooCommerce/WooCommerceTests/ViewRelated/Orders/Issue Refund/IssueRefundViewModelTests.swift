import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `IssueRefundViewModel`
///
final class IssueRefundViewModelTests: XCTestCase {

    func test_viewModel_does_not_have_shipping_section_on_order_without_shipping() {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: [])

        // When
        let viewModel = IssueRefundViewModel(order: order, currencySettings: currencySettings)

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
        let viewModel = IssueRefundViewModel(order: order, currencySettings: currencySettings)

        // Then
        let shippingSwitchRow = try XCTUnwrap(viewModel.sections[safe: 1]?.rows[safe: 0])
        XCTAssertTrue(shippingSwitchRow is IssueRefundViewModel.ShippingSwitchViewModel)
    }

    func test_viewModel_inserts_shipping_details_after_toggling_switch() throws {
        // Given
        let currencySettings = CurrencySettings()
        let order = MockOrders().makeOrder(shippingLines: MockOrders.sampleShippingLines())
        let viewModel = IssueRefundViewModel(order: order, currencySettings: currencySettings)
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
        let viewModel = IssueRefundViewModel(order: order, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(0), 3)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(1), 2)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(2), 1)
        XCTAssertEqual(viewModel.quantityAvailableForRefundForItemAtIndex(3), nil)
    }
}
