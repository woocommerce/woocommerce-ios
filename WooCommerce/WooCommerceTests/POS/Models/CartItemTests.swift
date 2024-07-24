import XCTest
@testable import WooCommerce
@testable import protocol Yosemite.POSItem
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
        XCTAssertFalse(CartItem.areOrderAndCartDifferent(order: order1, cartItems: cart1Items))
        XCTAssertTrue(CartItem.areOrderAndCartDifferent(order: order1, cartItems: cart2Items))
        XCTAssertTrue(CartItem.areOrderAndCartDifferent(order: order1, cartItems: []))
        // order2
        XCTAssertFalse(CartItem.areOrderAndCartDifferent(order: order2, cartItems: cart2Items))
        XCTAssertTrue(CartItem.areOrderAndCartDifferent(order: order2, cartItems: cart1Items))
        XCTAssertTrue(CartItem.areOrderAndCartDifferent(order: order2, cartItems: []))
        // nil order
        XCTAssertTrue(CartItem.areOrderAndCartDifferent(order: nil, cartItems: cart1Items))
        XCTAssertFalse(CartItem.areOrderAndCartDifferent(order: nil, cartItems: []))
    }
}

private extension CartItemTests {
    static func makeItem(productId: Int64, price: String) -> POSItem {
        return POSProduct(itemID: UUID(),
                          productID: productId,
                          name: "",
                          price: price,
                          formattedPrice: "",
                          itemCategories: [],
                          productImageSource: nil,
                          productType: .simple)
    }
}
