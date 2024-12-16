import Testing
@testable import Yosemite

struct POSOrderServiceTests {
    let sut: POSOrderService
    let mockReceiptsRemote: MockReceiptsOrderRemote
    let mockOrdersRemote: MockPOSOrdersRemote

    init() {
        let mockReceiptsRemote = MockReceiptsOrderRemote()
        let mockOrdersRemote = MockPOSOrdersRemote()

        self.mockReceiptsRemote = mockReceiptsRemote
        self.mockOrdersRemote = mockOrdersRemote

        self.sut = POSOrderService(siteID: 123, ordersRemote: mockOrdersRemote)
    }

    @Test
    func syncOrder_without_passing_an_order_creates_a_new_order() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: [], order: nil)

        // Then
        #expect(mockOrdersRemote.createPOSOrderCalled == true)
    }

    @Test
    func syncOrder_with_an_existing_order_updates_it() async throws {
        // Given
        let order = Order.fake().copy(siteID: 123, orderID: 456)

        // When
        _ = try await sut.syncOrder(cart: [], order: order)

        // Then
        #expect(mockOrdersRemote.updatePOSOrderCalled == true)
        #expect(mockOrdersRemote.spyUpdatePOSOrder == order)
    }

    @Test func syncOrder_updates_by_deleting_existing_items_and_adding_everything_from_the_cart() async throws {
        // Given
        let orderItems: [OrderItem] = [
            .fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1),
            .fake().copy(itemID: 2, name: "Item 2", productID: 102, quantity: 5)]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems)

        // When
        let cart: [POSCartItem] = [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 102, quantity: 1)
        ]
        _ = try await sut.syncOrder(cart: cart, order: order)

        // Then
        let updatedOrderItems = try #require(mockOrdersRemote.spyUpdatePOSOrder?.items)
        for item in updatedOrderItems {
            #expect(item.itemID == 0 || item.quantity == 0,
                    "Items should be deleted (quantity 0) or new (itemID 0)")
        }
    }

    @Test func syncOrder_after_removing_item_from_cart_deletes_it_from_the_order() async throws {
        // Given
        let orderItems: [OrderItem] = [
            .fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1),
            .fake().copy(itemID: 2, name: "Item 2", productID: 102, quantity: 5)]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems)

        // When
        let cart: [POSCartItem] = [
            makePOSCartItem(productID: 102, quantity: 1)
        ]
        _ = try await sut.syncOrder(cart: cart, order: order)

        // Then
        let updatedOrderItems = try #require(mockOrdersRemote.spyUpdatePOSOrder?.items)

        #expect(updatedOrderItems.contains(where: { item in
            item.itemID == 1 && item.quantity == 0
        }), "Item 1 should be deleted")

        #expect(!updatedOrderItems.contains(where: { item in
            item.productID == 100 && item.quantity > 0
        }), "Product for item 1 should not be re-added")

        #expect(updatedOrderItems.contains(where: { item in
            item.productID == 102 && item.quantity > 0
        }), "Product for item 2 should be re-added")
    }

    @Test func syncOrder_after_adding_to_cart_adds_it_to_the_order() async throws {
        // Given
        let orderItems: [OrderItem] = [
            .fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1)
        ]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems)

        // When
        let cart: [POSCartItem] = [
            makePOSCartItem(productID: 100, quantity: 1),
            makePOSCartItem(productID: 102, quantity: 5)
        ]
        _ = try await sut.syncOrder(cart: cart, order: order)

        // Then
        let updatedOrderItems = try #require(mockOrdersRemote.spyUpdatePOSOrder?.items)

        #expect(updatedOrderItems.contains(where: { item in
            item.productID == 102 && item.quantity == 5
        }), "Item for product 102 should be added")
    }
}

private func makePOSCartItem(
    productID: Int64,
    quantity: Decimal) -> POSCartItem {
        return POSCartItem(
            item: POSProduct(id: UUID(),
                             name: "",
                             formattedPrice: "",
                             productID: productID,
                             price: ""),
            quantity: quantity
        )
    }
