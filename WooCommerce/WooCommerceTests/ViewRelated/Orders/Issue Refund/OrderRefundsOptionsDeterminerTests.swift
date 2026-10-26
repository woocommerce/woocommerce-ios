import XCTest
import Yosemite
import Foundation
import WooFoundation
@testable import WooCommerce

final class OrderRefundsOptionsDeterminerTests: XCTestCase {
    private var sut: OrderRefundsOptionsDeterminer!

    override func setUp() {
        super.setUp()

        sut = OrderRefundsOptionsDeterminer()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func test_isAnythingToRefund_when_all_items_and_amount_are_refunded_returns_false() {
        // Given
        let orderTotal = "23"
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
        ]
        let order = Order.fake().copy(total: orderTotal, items: items)
        let refund = MockRefunds.sampleRefund(amount: orderTotal,
                                              items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -2),
                                              ])

        // When
        let result = sut.isAnythingToRefund(from: order, with: [refund], currencyFormatter: currencyFormatter)

        // Then
        XCTAssertFalse(result)
    }

    func test_isAnythingToRefund_when_all_items_are_refunded_but_amount_is_not_returns_true() {
        // Given
        let orderTotal = "23"
        let refundedAmount = "15"
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
        ]
        let order = Order.fake().copy(total: orderTotal, items: items)
        let refund = MockRefunds.sampleRefund(amount: refundedAmount,
                                              items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -2),
                                              ])

        // When
        let result = sut.isAnythingToRefund(from: order, with: [refund], currencyFormatter: currencyFormatter)

        // Then
        XCTAssertTrue(result)
    }

    func test_isAnythingToRefund_when_not_all_items_are_refunded_but_amount_is_returns_true() {
        // Given
        let orderTotal = "23"
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
        ]
        let order = Order.fake().copy(total: orderTotal, items: items)
        let refund = MockRefunds.sampleRefund(amount: orderTotal,
                                              items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3)
                                              ])

        // When
        let result = sut.isAnythingToRefund(from: order, with: [refund], currencyFormatter: currencyFormatter)

        // Then
        XCTAssertTrue(result)
    }

    func test_determineRefundableOrderItems_when_all_items_are_refunded_returns_empty_array() {
        // Given
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2),
        ]
        let order = Order.fake().copy(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3),
            MockRefunds.sampleRefundItem(productID: 2, quantity: -2),
        ])

        // When
        let result = sut.determineRefundableOrderItems(from: order, with: [refund])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_determineRefundableOrderItems_when_not_all_items_are_refunded_returns_the_remaining_items() {
        // Given
        let notRefundedItem = MockOrderItem.sampleItem(itemID: 2, productID: 2, quantity: 2)
        let items = [
            MockOrderItem.sampleItem(itemID: 1, productID: 1, quantity: 3),
            notRefundedItem,
        ]
        let order = Order.fake().copy(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: 1, quantity: -3)
        ])

        // When
        let expectedResult = [RefundableOrderItem(item: notRefundedItem, quantity: 2)]
        let result = sut.determineRefundableOrderItems(from: order, with: [refund])

        // Then
        XCTAssertEqual(result, expectedResult)
    }

    func test_determineRefundableOrderItems_when_items_are_refunded_partially_returns_the_remaining_items() {
        // Given
        let productId: Int64 = 2
        let partiallyRefundedItem = MockOrderItem.sampleItem(itemID: 2, productID: productId, quantity: 2)
        let items = [partiallyRefundedItem]
        let order = Order.fake().copy(items: items)
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: productId, quantity: -1)
        ])

        let newQuantity = partiallyRefundedItem.quantity + (refund.items.first?.quantity ?? 0)

        // When
        var expectedItem = RefundableOrderItem(item: partiallyRefundedItem, quantity: newQuantity)
        expectedItem.refundedItems = refund.items
        let expectedResult = [expectedItem]
        let result = sut.determineRefundableOrderItems(from: order, with: [refund])

        // Then
        XCTAssertEqual(result, expectedResult)
    }

    func test_determineRefundableOrderItems_when_duplicate_product_line_has_refunded_item_id_returns_unrefunded_duplicate() {
        // Given
        let productID: Int64 = 5
        let refundedItem = MockOrderItem.sampleItem(itemID: 101, productID: productID, quantity: 1)
        let unrefundedItem = MockOrderItem.sampleItem(itemID: 102, productID: productID, quantity: 1)
        let order = Order.fake().copy(items: [refundedItem, unrefundedItem])
        let refund = MockRefunds.sampleRefund(items: [
            MockRefunds.sampleRefundItem(productID: productID, refundedItemID: "101", quantity: -1)
        ])

        // When
        let result = sut.determineRefundableOrderItems(from: order, with: [refund])

        // Then
        XCTAssertEqual(result, [RefundableOrderItem(item: unrefundedItem, quantity: 1)])
    }

    func shouldRefundCustomAmountsByDefault_when_the_order_has_only_items_return_false() {
        // Given
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [])

        // When
        let result = sut.shouldRefundCustomAmountsByDefault(from: order)

        // Then
        XCTAssertFalse(result)
    }

    func shouldRefundCustomAmountsByDefault_when_the_order_has_items_and_custom_amounts_return_false() {
        // Given
        let items = [
            MockOrderItem.sampleItem(itemID: 1, quantity: 3),
        ]
        let order = MockOrders().makeOrder(items: items, fees: [OrderFeeLine.fake()])

        // When
        let result = sut.shouldRefundCustomAmountsByDefault(from: order)

        // Then
        XCTAssertFalse(result)
    }

    func shouldRefundCustomAmountsByDefault_when_the_order_has_only_custom_amounts_return_false() {
        // Given
        let order = MockOrders().makeOrder(items: [], fees: [OrderFeeLine.fake()])

        // When
        let result = sut.shouldRefundCustomAmountsByDefault(from: order)

        // Then
        XCTAssertTrue(result)
    }
    func test_remaining_fees_when_partially_refunded_then_preserves_remaining_net_tax_and_sign() throws {
        for sign in ["", "-"] {
            // Given
            let fee = OrderFeeLine.fake().copy(feeID: 1, total: sign + "2.00", totalTax: sign + "0.10",
                                               taxes: [.init(taxID: 3, subtotal: "", total: sign + "0.10")])
            let refundSign = sign.isEmpty ? "-" : ""
            let refunded = fee.copy(feeID: 99, total: refundSign + "0.50", totalTax: refundSign + "0.02",
                                     taxes: [.init(taxID: 3, subtotal: "", total: refundSign + "0.02")], refundedItemID: .some(1))
            let order = Order.fake().copy(fees: [fee])
            // When
            let remaining = try XCTUnwrap(OrderRefundsOptionsDeterminer.remainingFees(in: order, refunds: [Refund.fake().copy(feeLines: [refunded])]).first)
            // Then
            XCTAssertEqual(remaining.total, sign + "1.5")
            XCTAssertEqual(remaining.totalTax, sign + "0.08")
            XCTAssertEqual(remaining.taxes.first?.total, sign + "0.08")
        }
    }

    func test_remaining_shipping_when_partially_refunded_then_uses_original_id_and_remaining_rates() throws {
        for sign in ["", "-"] {
            // Given
            let line = ShippingLine(shippingID: 1, methodTitle: "Standard", methodID: "standard", total: sign + "5", totalTax: sign + "0.25",
                                    taxes: [.init(taxID: 3, subtotal: "", total: sign + "0.25")])
            let refundSign = sign.isEmpty ? "-" : ""
            let refunded = line.copy(shippingID: 99, total: refundSign + "2", totalTax: refundSign + "0.10",
                                     taxes: [.init(taxID: 3, subtotal: "", total: refundSign + "0.10")], refundedItemID: .some(1))
            let order = Order.fake().copy(shippingLines: [line])
            // When
            let remaining = try XCTUnwrap(OrderRefundsOptionsDeterminer.remainingShipping(in: order,
                                                          refunds: [Refund.fake().copy(shippingLines: [refunded])])?.first)
            // Then
            XCTAssertEqual(remaining.shippingID, 1)
            XCTAssertEqual(remaining.total, sign + "3")
            XCTAssertEqual(remaining.totalTax, sign + "0.15")
            XCTAssertEqual(remaining.taxes.first?.total, sign + "0.15")
        }
    }
}
