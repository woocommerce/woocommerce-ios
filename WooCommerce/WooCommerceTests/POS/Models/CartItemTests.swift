import XCTest
@testable import WooCommerce
@testable import typealias Yosemite.POSOrderableItem
@testable import struct Yosemite.Order
@testable import struct Yosemite.OrderItem
@testable import struct Yosemite.POSProduct
@testable import enum Yosemite.OrderFactory

final class CartItemTests: XCTestCase {
    func test_are_order_and_cart_different() {
        // Given/When

        // cart
        let productId: Int64 = 1
        let price = "1"
        let item = CartItemTests.makeItem(productId: productId, price: price)
        let quantity = 2
        let cartItem = CartItem(id: UUID(), item: item, quantity: quantity)
        let cart1Items: [CartItem] = [cartItem]
        let cart2Items: [CartItem] = [cartItem, cartItem]
        // order
        let orderPrice = NSDecimalNumber(string: price)
        let orderItem = OrderItem.fake().copy(productID: productId, quantity: Decimal(quantity), price: orderPrice)
        let order1Items: [OrderItem] = [orderItem]
        let order2Items: [OrderItem] = [orderItem, orderItem]
        let order1 = OrderFactory.emptyNewOrder.copy(items: order1Items)
        let order2 = OrderFactory.emptyNewOrder.copy(items: order2Items)

        // Then
        // order1
        XCTAssertTrue(cart1Items.matchesOrder(order1))
        XCTAssertFalse(cart2Items.matchesOrder(order1))
        XCTAssertFalse([CartItem]().matchesOrder(order1))
        // order2
        XCTAssertTrue(cart2Items.matchesOrder(order2))
        XCTAssertFalse(cart1Items.matchesOrder(order2))
        XCTAssertFalse([CartItem]().matchesOrder(order2))
        // nil order
        XCTAssertFalse(cart1Items.matchesOrder(nil))
        XCTAssertTrue([CartItem]().matchesOrder(nil))
    }
}

private extension CartItemTests {
    static func makeItem(productId: Int64, price: String) -> any POSOrderableItem {
        return POSProduct(id: UUID(), name: "", formattedPrice: "", productID: productId, price: price)
    }
}
