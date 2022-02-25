import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class ProductInputTransformerTests: XCTestCase {

    private let sampleProductID: Int64 = 123
    private let sampleProductVariationID: Int64 = 345
    private let sampleInputID: Int64 = 567

    func test_sending_a_new_product_input_adds_an_item_to_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.update(input: input, on: originalOrder)

        // Then
        let item = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.quantity, input.quantity)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.variationID, 0)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "9.99")
    }

    func test_sending_a_new_product_variation_input_adds_an_item_to_order() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(productID: sampleProductID, productVariationID: sampleProductVariationID, price: "9.99")
        let input = OrderSyncProductInput(product: .variation(productVariation), quantity: 1)
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.update(input: input, on: originalOrder)

        // Then
        let item = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.quantity, input.quantity)
        XCTAssertEqual(item.productID, productVariation.productID)
        XCTAssertEqual(item.variationID, productVariation.productVariationID)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "9.99")
    }

    func test_sending_a_new_product_input_twice_adds_adds_two_items_to_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let input1 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder)

        // When
        let input2 = OrderSyncProductInput(id: sampleInputID + 1, product: .product(product), quantity: 1)
        let update2 = ProductInputTransformer.update(input: input2, on: update1)

        // Then
        XCTAssertEqual(update2.items.count, 2)
    }

    func test_sending_an_update_product_input_updates_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let input1 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder)

        // When
        let input2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 2)
        let update2 = ProductInputTransformer.update(input: input2, on: update1)

        // Then
        let item = try XCTUnwrap(update2.items.first)
        XCTAssertEqual(item.itemID, input2.id)
        XCTAssertEqual(item.quantity, input2.quantity)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "19.98")
    }

    func test_sending_an_zero_quantity_update_product_input_deletes_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let input1 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder)

        // When
        let input2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 0)
        let update2 = ProductInputTransformer.update(input: input2, on: update1)

        // Then
        XCTAssertEqual(update2.items.count, 0)
    }
}
