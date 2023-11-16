import XCTest

import WooFoundation
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

    func test_orderTotal_includes_expected_totals() {
        let shippingTotal = 5
        let taxTotal = 3
        let firstItemTotal = 1
        let secondItemTotal = 8
        let firstFeeTotal = 2
        let secondFeeTotal = 8

        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(shippingTotal: String(shippingTotal),
                                      totalTax: String(taxTotal),
                                      items: [OrderItem.fake().copy(subtotal: "2.00",
                                                                    total: String(firstItemTotal)),
                                              OrderItem.fake().copy(subtotal: "8.00", total: String(secondItemTotal))],
                                      fees: [OrderFeeLine.fake().copy(total: String(firstFeeTotal)), OrderFeeLine.fake().copy(total: String(secondFeeTotal))])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)

        // Then
        let expectedTotal = shippingTotal + taxTotal + firstItemTotal + secondItemTotal + firstFeeTotal + secondFeeTotal
        XCTAssertEqual(orderTotalsCalculator.orderTotal, NSDecimalNumber(decimal: Decimal(expectedTotal)))
    }

    func test_updateOrderTotal_returns_order_with_expected_total() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(shippingTotal: "5.00",
                                      totalTax: "3.00",
                                      items: [OrderItem.fake().copy(subtotal: "2.00", total: "2.00"), OrderItem.fake().copy(subtotal: "8.00", total: "8.00")],
                                      fees: [OrderFeeLine.fake().copy(total: "2.00"), OrderFeeLine.fake().copy(total: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)
        let updatedOrder = orderTotalsCalculator.updateOrderTotal()

        // Then
        XCTAssertEqual(updatedOrder.total, "28")
    }

    func test_updateOrderTotal_when_there_are_discounts_then_returns_order_with_expected_total() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let order = Order.fake().copy(shippingTotal: "5.00",
                                      totalTax: "3.00",
                                      items: [OrderItem.fake().copy(subtotal: "2.00", total: "1.00"), OrderItem.fake().copy(subtotal: "8.00", total: "5.00")],
                                      fees: [OrderFeeLine.fake().copy(total: "2.00"), OrderFeeLine.fake().copy(total: "8.00")])

        // When
        let orderTotalsCalculator = OrderTotalsCalculator(for: order, using: currencyFormatter)
        let updatedOrder = orderTotalsCalculator.updateOrderTotal()

        // Then
        XCTAssertEqual(updatedOrder.total, "24")
    }
}
