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
    func syncOrder_creates_a_new_order() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), currency: .USD)

        // Then
        #expect(mockOrdersRemote.createPOSOrderCalled == true)
    }

    @Test
    func syncOrder_creates_a_new_order_using_passed_currency() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), currency: .EUR)

        // Then
        #expect(mockOrdersRemote.spyCreatePOSOrder?.currency.uppercased() == "EUR")
        let fields = try #require(mockOrdersRemote.spyCreatePOSOrderFields)
        #expect(fields.contains(.currency) == true)
    }

    @Test
    func syncOrder_adds_cart_items_to_new_order() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 102, quantity: 1)
        ])

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderItems = try #require(mockOrdersRemote.spyCreatePOSOrder?.items)
        #expect(createdOrderItems.contains(where: { item in
            item.productID == 100 && item.quantity == 2
        }))
        #expect(createdOrderItems.contains(where: { item in
            item.productID == 102 && item.quantity == 1
        }))
    }

    @Test
    func syncOrder_adds_cart_coupons_to_new_order() async throws {
        // Given
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [.init(id: UUID(), code: "SAVE10")]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderCoupons = try #require(mockOrdersRemote.spyCreatePOSOrder?.coupons)
        #expect(createdOrderCoupons.count == 1)
        #expect(createdOrderCoupons.first?.code == "SAVE10")
    }

    @Test
    func syncOrder_with_multiple_coupons_adds_all_to_new_order() async throws {
        // Given
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [
                .init(id: UUID(), code: "SAVE10"),
                .init(id: UUID(), code: "FREESHIP"),
                .init(id: UUID(), code: "EXTRA5")
            ]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderCoupons = try #require(mockOrdersRemote.spyCreatePOSOrder?.coupons)
        #expect(createdOrderCoupons.count == 3)
        #expect(createdOrderCoupons.contains(where: { $0.code == "SAVE10" }))
        #expect(createdOrderCoupons.contains(where: { $0.code == "FREESHIP" }))
        #expect(createdOrderCoupons.contains(where: { $0.code == "EXTRA5" }))
    }

    @Test
    func syncOrder_sanitizes_items_before_sending_to_remote() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 101, quantity: 1)
        ])

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let orderSentToRemote = try #require(mockOrdersRemote.spyCreatePOSOrder)

        // Verify all items in the order are sanitized
        for item in orderSentToRemote.items {
            #expect(item.itemID == 0, "Item ID should be zero for new items")
            #expect(item.total == "", "Total should be empty string")
            #expect(item.subtotal == "", "Subtotal should be empty string")
        }
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
