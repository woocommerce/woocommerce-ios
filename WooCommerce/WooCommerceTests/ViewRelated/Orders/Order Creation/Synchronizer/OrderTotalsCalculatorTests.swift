import XCTest

@testable import WooCommerce
@testable import Yosemite

class OrderTotalsCalculatorTests: XCTestCase {

    func test_itemsTotal_includes_all_item_subtotals() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(items: [OrderItem.fake().copy(subtotal: "2.00"), OrderItem.fake().copy(subtotal: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)

        // Then
        XCTAssertEqual(orderTotalsCalculator.itemsTotal, 10)
    }

    func test_feesTotal_includes_all_fee_line_totals() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(fees: [OrderFeeLine.fake().copy(total: "2.00"), OrderFeeLine.fake().copy(total: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)

        // Then
        XCTAssertEqual(orderTotalsCalculator.feesTotal, 10)
    }

    func test_feesBaseAmountForPercentage_includes_expected_totals() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(shippingTotal: "5.00",
                                      totalTax: "3.00",
                                      items: [OrderItem.fake().copy(subtotal: "2.00"), OrderItem.fake().copy(subtotal: "8.00")],
                                      fees: [OrderFeeLine.fake().copy(total: "2.00"), OrderFeeLine.fake().copy(total: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)

        // Then
        XCTAssertEqual(orderTotalsCalculator.feesBaseAmountForPercentage, 18)
    }

    func test_updateOrderTotal_returns_order_with_expected_total() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(shippingTotal: "5.00",
                                      totalTax: "3.00",
                                      items: [OrderItem.fake().copy(subtotal: "2.00"), OrderItem.fake().copy(subtotal: "8.00")],
                                      fees: [OrderFeeLine.fake().copy(total: "2.00"), OrderFeeLine.fake().copy(total: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)
        let updatedOrder = orderTotalsCalculator.updateOrderTotal()

        // Then
        XCTAssertEqual(updatedOrder.total, "28")
    }
}
