import XCTest
import Yosemite
import Foundation
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
        let expectedResult = [RefundableOrderItem(item: partiallyRefundedItem, quantity: newQuantity)]
        let result = sut.determineRefundableOrderItems(from: order, with: [refund])

        // Then
        XCTAssertEqual(result, expectedResult)
    }
}
