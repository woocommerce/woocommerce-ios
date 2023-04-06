import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class ProductInputTransformerTests: XCTestCase {

    private let sampleProductID: Int64 = 123
    private let anotherSampleProductID: Int64 = 987
    private let sampleProductVariationID: Int64 = 345
    private let anotherSampleProductVariationID: Int64 = 789
    private let sampleInputID: Int64 = 567

    func test_sending_a_new_product_input_adds_an_item_to_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.update(input: input, on: originalOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        let item = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.quantity, input.quantity)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.variationID, 0)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "9.99")
        XCTAssertEqual(item.total, "9.99")
    }

    func test_updateMultipleItems_when_sending_multiple_new_inputs_then_adds_multiple_items_to_an_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let anotherProduct = Product.fake().copy(productID: anotherSampleProductID, price: "9.99")
        let input = [
            OrderSyncProductInput(product: .product(product), quantity: 1),
            OrderSyncProductInput(product: .product(anotherProduct), quantity: 1)
        ]
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.updateMultipleItems(
            with: input,
            on: originalOrder,
            shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        let items = try XCTUnwrap(updatedOrder.items)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].itemID, input[0].id)
        XCTAssertEqual(items[1].itemID, input[1].id)
        XCTAssertEqual(items[0].quantity, input[0].quantity)
        XCTAssertEqual(items[1].quantity, input[1].quantity)
        XCTAssertEqual(items[0].productID, product.productID)
        XCTAssertEqual(items[1].productID, anotherProduct.productID)
        let _ = items.map { item in
            XCTAssertEqual(item.variationID, 0)
            XCTAssertEqual(item.price, 9.99)
            XCTAssertEqual(item.subtotal, "9.99")
            XCTAssertEqual(item.total, "9.99")
        }
    }

    func test_sending_a_new_product_variation_input_adds_an_item_to_order() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(productID: sampleProductID, productVariationID: sampleProductVariationID, price: "9.99")
        let input = OrderSyncProductInput(product: .variation(productVariation), quantity: 1)
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.update(input: input, on: originalOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        let item = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.quantity, input.quantity)
        XCTAssertEqual(item.productID, productVariation.productID)
        XCTAssertEqual(item.variationID, productVariation.productVariationID)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "9.99")
        XCTAssertEqual(item.total, "9.99")
    }

    func test_updateMultipleItems_when_sending_multiple_new_product_variation_inputs_then_adds_multiple_items_to_an_order() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(productID: sampleProductID,
                                                            productVariationID: sampleProductVariationID,
                                                            price: "9.99")
        let anotherProductVariation = ProductVariation.fake().copy(productID: anotherSampleProductID,
                                                                   productVariationID: anotherSampleProductVariationID,
                                                                   price: "9.99")
        let input = [
            OrderSyncProductInput(product: .variation(productVariation), quantity: 1),
            OrderSyncProductInput(product: .variation(anotherProductVariation), quantity: 1)
        ]
        let originalOrder = OrderFactory.emptyNewOrder

        // When
        let updatedOrder = ProductInputTransformer.updateMultipleItems(
            with: input,
            on: originalOrder,
            shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        let items = try XCTUnwrap(updatedOrder.items)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].itemID, input[0].id)
        XCTAssertEqual(items[1].itemID, input[1].id)
        XCTAssertEqual(items[0].quantity, input[0].quantity)
        XCTAssertEqual(items[1].quantity, input[1].quantity)
        XCTAssertEqual(items[0].productID, productVariation.productID)
        XCTAssertEqual(items[1].productID, anotherProductVariation.productID)
        XCTAssertEqual(items[0].variationID, productVariation.productVariationID)
        XCTAssertEqual(items[1].variationID, anotherProductVariation.productVariationID)
        let _ = items.map { item in
            XCTAssertEqual(item.price, 9.99)
            XCTAssertEqual(item.subtotal, "9.99")
            XCTAssertEqual(item.total, "9.99")
        }
    }

    func test_sending_a_new_product_input_twice_adds_adds_two_items_to_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let input1 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // When
        let input2 = OrderSyncProductInput(id: sampleInputID + 1, product: .product(product), quantity: 1)
        let update2 = ProductInputTransformer.update(input: input2, on: update1, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        XCTAssertEqual(update2.items.count, 2)
    }

    func test_sending_an_update_product_input_updates_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let input1 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // When
        let input2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 2)
        let update2 = ProductInputTransformer.update(input: input2, on: update1, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        let item = try XCTUnwrap(update2.items.first)
        XCTAssertEqual(item.itemID, input2.id)
        XCTAssertEqual(item.quantity, input2.quantity)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "19.98")
        XCTAssertEqual(item.total, "19.98")
    }

    func test_updatedOrder_when_updateMultipleItems_sends_an_updated_product_input_then_updates_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let productInput = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let initialOrder = ProductInputTransformer.updateMultipleItems(with: [productInput],
                                                                       on: OrderFactory.emptyNewOrder,
                                                                       shouldUpdateOrDeleteZeroQuantities: .delete)

        // When
        let productInput2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 2)
        let updatedOrder = ProductInputTransformer.updateMultipleItems(with: [productInput2], on: initialOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        // Confirm that we still have only 1 item
        XCTAssertEqual(updatedOrder.items.count, 1)
        let item = try XCTUnwrap(updatedOrder.items.first)
        // Confirm that the item is updated
        XCTAssertEqual(item.itemID, productInput2.id)
        XCTAssertEqual(item.quantity, productInput2.quantity)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.price, 9.99)
        XCTAssertEqual(item.subtotal, "19.98")
        XCTAssertEqual(item.total, "19.98")

    }

    func test_sending_an_update_product_input_uses_item_price_from_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let item = OrderItem.fake().copy(itemID: sampleInputID, price: 8.00)
        let order = Order.fake().copy(items: [item])

        // When
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 2)
        let updatedOrder = ProductInputTransformer.update(input: input, on: order, shouldUpdateOrDeleteZeroQuantities: .update)

        // Then
        let updatedItem = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(updatedItem.price, 8.00) // Existing item price from order.
        XCTAssertEqual(updatedItem.subtotal, "16")
        XCTAssertEqual(updatedItem.total, "16")
    }

    func test_updatedOrder_when_updateMultipleItems_sends_an_updated_product_input_then_updates_price_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "9.99")
        let item = OrderItem.fake().copy(itemID: sampleInputID, price: 8.00)
        let order = Order.fake().copy(items: [item])

        // When
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 2)
        let updatedOrder = ProductInputTransformer.updateMultipleItems(with: [input], on: order, shouldUpdateOrDeleteZeroQuantities: .update)

        // Then
        let updatedItem = try XCTUnwrap(updatedOrder.items.first)
        XCTAssertEqual(updatedItem.price, 8.00) // Existing item price from order.
        XCTAssertEqual(updatedItem.subtotal, "16")
        XCTAssertEqual(updatedItem.total, "16")
    }

    func test_sending_a_zero_quantity_update_product_input_deletes_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let input1 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder, shouldUpdateOrDeleteZeroQuantities: .delete)

        // When
        let input2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 0)
        let update2 = ProductInputTransformer.update(input: input2, on: update1, shouldUpdateOrDeleteZeroQuantities: .delete)

        // Then
        XCTAssertEqual(update2.items.count, 0)
    }

    func test_order_when_updateMultipleItems_with_zero_quantity_product_input_and_deletes_zero_quantities_then_deletes_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let productInput = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let initialOrderUpdate = ProductInputTransformer.updateMultipleItems(with: [productInput],
                                                                             on: OrderFactory.emptyNewOrder,
                                                                             shouldUpdateOrDeleteZeroQuantities: .delete)

        // When
        let productInput2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 0)
        let orderUpdate = ProductInputTransformer.updateMultipleItems(with: [productInput2],
                                                                      on: initialOrderUpdate,
                                                                      shouldUpdateOrDeleteZeroQuantities: .delete)
        // Then
        XCTAssertEqual(orderUpdate.items.count, 0)
    }

    func test_sending_a_zero_quantity_update_product_input_does_not_delete_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let input1 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let update1 = ProductInputTransformer.update(input: input1, on: OrderFactory.emptyNewOrder, shouldUpdateOrDeleteZeroQuantities: .update)

        // When
        let input2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 0)
        let update2 = ProductInputTransformer.update(input: input2, on: update1, shouldUpdateOrDeleteZeroQuantities: .update)

        // Then
        let item = try XCTUnwrap(update2.items.first)
        XCTAssertEqual(item.quantity, input2.quantity)
    }

    func test_order_when_updateMultipleItems_with_zero_quantity_product_input_and_updates_zero_quantities_then_updates_item_on_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let productInput = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 1)
        let initialOrderUpdate = ProductInputTransformer.updateMultipleItems(with: [productInput],
                                                                             on: OrderFactory.emptyNewOrder,
                                                                             shouldUpdateOrDeleteZeroQuantities: .update)

        // When
        let productInput2 = OrderSyncProductInput(id: sampleProductID, product: .product(product), quantity: 0)
        let orderUpdate = ProductInputTransformer.updateMultipleItems(with: [productInput2],
                                                                      on: initialOrderUpdate,
                                                                      shouldUpdateOrDeleteZeroQuantities: .update)

        // Then
        let item = try XCTUnwrap(orderUpdate.items.first)
        XCTAssertEqual(item.quantity, productInput2.quantity)
    }
}
