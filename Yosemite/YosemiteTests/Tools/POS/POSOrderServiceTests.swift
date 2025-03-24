import Testing
@testable import Yosemite

struct POSOrderServiceTests {
    let sut: POSOrderService
    let mockOrdersRemote: MockPOSOrdersRemote

    init() {
        let mockOrdersRemote = MockPOSOrdersRemote()

        self.mockOrdersRemote = mockOrdersRemote

        self.sut = POSOrderService(siteID: 123, ordersRemote: mockOrdersRemote)
    }

    @Test
    func syncOrder_without_passing_an_order_creates_a_new_order() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), order: nil, currency: .USD)

        // Then
        #expect(mockOrdersRemote.createPOSOrderCalled == true)
    }

    @Test
    func syncOrder_without_passing_an_order_creates_a_new_order_using_passed_currency() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), order: nil, currency: .EUR)

        // Then
        #expect(mockOrdersRemote.spyCreatePOSOrder?.currency.uppercased() == "EUR")
        let fields = try #require(mockOrdersRemote.spyCreatePOSOrderFields)
        #expect(fields.contains(.currency) == true)
    }

    @Test
    func syncOrder_with_an_existing_order_updates_it() async throws {
        // Given
        let order = Order.fake().copy(siteID: 123, orderID: 456, currency: "JPY")

        // When
        _ = try await sut.syncOrder(cart: .init(), order: order, currency: .JPY)

        // Then
        #expect(mockOrdersRemote.updatePOSOrderCalled == true)
        #expect(mockOrdersRemote.spyUpdatePOSOrder == order)
    }

    @Test
    func syncOrder_with_an_existing_order_does_not_change_the_currency() async throws {
        // Given
        let order = Order.fake().copy(siteID: 123, orderID: 456, currency: "USD")

        // When
        _ = try await sut.syncOrder(cart: .init(), order: order, currency: .JPY)

        // Then
        #expect(mockOrdersRemote.updatePOSOrderCalled == true)
        #expect(mockOrdersRemote.spyUpdatePOSOrder?.currency.uppercased() == "USD")
    }

    @Test func syncOrder_updates_by_deleting_existing_items_and_adding_everything_from_the_cart() async throws {
        // Given
        let orderItems: [OrderItem] = [
            .fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1),
            .fake().copy(itemID: 2, name: "Item 2", productID: 102, quantity: 5)]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems)

        // When
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 102, quantity: 1)
        ])
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

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
        let cart = POSCart(items: [
            makePOSCartItem(productID: 102, quantity: 1)
        ])
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

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
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 1),
            makePOSCartItem(productID: 102, quantity: 5)
        ])
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

        // Then
        let updatedOrderItems = try #require(mockOrdersRemote.spyUpdatePOSOrder?.items)

        #expect(updatedOrderItems.contains(where: { item in
            item.productID == 102 && item.quantity == 5
        }), "Item for product 102 should be added")
    }

    @Test func syncOrder_after_adding_coupon_to_cart_adds_it_to_the_order() async throws {
        // Given
        let orderItems = [OrderItem.fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1)]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems, coupons: [])

        // When
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [.init(code: "SAVE10")]
        )
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

        // Then
        let updatedOrderCoupons = try #require(mockOrdersRemote.spyUpdatePOSOrder?.coupons)
        #expect(updatedOrderCoupons.count == 1)
        #expect(updatedOrderCoupons.first?.code == "SAVE10")
    }

    @Test func syncOrder_after_removing_coupon_from_cart_removes_it_from_the_order() async throws {
        // Given
        let orderItems = [OrderItem.fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1)]
        let existingCoupons = [OrderCouponLine.fake().copy(code: "SAVE10")]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems, coupons: existingCoupons)

        // When
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [] // Empty coupons in cart
        )
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

        // Then
        let updatedOrderCoupons = try #require(mockOrdersRemote.spyUpdatePOSOrder?.coupons)
        #expect(updatedOrderCoupons.isEmpty)
    }

    @Test func syncOrder_with_multiple_coupons_handles_mixed_changes() async throws {
        // Given
        let orderItems = [OrderItem.fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1)]
        let existingCoupons = [
            OrderCouponLine.fake().copy(code: "REMOVE1"),
            OrderCouponLine.fake().copy(code: "KEEP1"),
            OrderCouponLine.fake().copy(code: "REMOVE2")
        ]
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems, coupons: existingCoupons)

        // When
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [
                .init(code: "KEEP1"),
                .init(code: "NEW1"),
                .init(code: "NEW2")
            ]
        )
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

        // Then
        let updatedOrderCoupons = try #require(mockOrdersRemote.spyUpdatePOSOrder?.coupons)

        // Verify kept coupon
        #expect(updatedOrderCoupons.contains(where: { $0.code == "KEEP1" }))

        // Verify removed coupons
        #expect(!updatedOrderCoupons.contains(where: { $0.code == "REMOVE1" }))
        #expect(!updatedOrderCoupons.contains(where: { $0.code == "REMOVE2" }))

        // Verify new coupons
        #expect(updatedOrderCoupons.contains(where: { $0.code == "NEW1" }))
        #expect(updatedOrderCoupons.contains(where: { $0.code == "NEW2" }))

        // Verify total count
        #expect(updatedOrderCoupons.count == 3)
    }

    @Test func syncOrder_with_unchanged_coupons_preserves_existing_coupon_data() async throws {
        // Given
        let orderItems = [OrderItem.fake().copy(itemID: 1, name: "Item 1", productID: 100, quantity: 1)]
        let existingCoupon = OrderCouponLine.fake().copy(code: "KEEP1", discount: "10.00")
        let order = Order.fake().copy(siteID: 123, orderID: 456, items: orderItems, coupons: [existingCoupon])

        // When
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [.init(code: "KEEP1")] // Same coupon in cart
        )
        _ = try await sut.syncOrder(cart: cart, order: order, currency: .USD)

        // Then
        let updatedOrderCoupons = try #require(mockOrdersRemote.spyUpdatePOSOrder?.coupons)
        #expect(updatedOrderCoupons.count == 1)
        #expect(updatedOrderCoupons.first?.code == "KEEP1")
        #expect(updatedOrderCoupons.first?.discount == "10.00", "Existing coupon data should be preserved")
    }
}

private func makePOSCartItem(
    productID: Int64,
    quantity: Decimal) -> POSCartItem {
        return POSCartItem(
            item: POSSimpleProduct(id: UUID(),
                                   name: "",
                                   formattedPrice: "",
                                   productID: productID,
                                   price: ""),
            quantity: quantity
        )
    }
