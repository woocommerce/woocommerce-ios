import Testing
@testable import Yosemite

struct POSCartItemTests {

    @Test func empty_cart_matches_nil_order() async throws {
        // Given
        let sut = [POSCartItem]()

        // When, Then
        #expect(sut.matches(order: nil) == true)
    }

    @Test func empty_cart_matches_empty_order() async throws {
        // Given
        let order = Order.fake()

        // When, Then
        #expect([POSCartItem]().matches(order: order) == true)
    }

    @Test func cart_with_item_does_not_match_nil_order() async throws {
        // Given
        let sut = [makeCartItem(quantity: 1, matching: [])]

        // When, Then
        #expect(sut.matches(order: nil) == false)
    }

    @Test func cart_with_item_matches_order_with_matching_item() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 1)
        let order = Order.fake().copy(items: [orderItem])
        let sut = [makeCartItem(quantity: 1, matching: [orderItem])]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    @Test func cart_with_item_having_higher_quantity_does_not_match_order_with_matching_item() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 1)
        let order = Order.fake().copy(items: [orderItem])
        let sut = [makeCartItem(quantity: 2, matching: [orderItem])]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_multiple_items_summing_to_higher_quantity_does_not_match_order_with_matching_item() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 1)
        let order = Order.fake().copy(items: [orderItem])
        let sut = [makeCartItem(quantity: 1, matching: [orderItem]),
                   makeCartItem(quantity: 1, matching: [orderItem])]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_item_does_not_match_order_with_matching_item_but_higher_quantity() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 3)
        let order = Order.fake().copy(items: [orderItem])
        let sut = [makeCartItem(quantity: 2, matching: [orderItem])]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_multiple_items_summing_to_lower_quantity_does_not_match_order_with_matching_item() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 3)
        let order = Order.fake().copy(items: [orderItem])
        let sut = [makeCartItem(quantity: 1, matching: [orderItem]),
                   makeCartItem(quantity: 1, matching: [orderItem])]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_item_having_quantity_2_matches_order_with_multiple_matching_items_summing_to_quantity_2() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 1)
        let order = Order.fake().copy(items: [orderItem, orderItem])
        let sut = [makeCartItem(quantity: 2, matcher: { $0.productID == 3 })]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    @Test func cart_with_item_matching_order_item_does_not_match_order_with_additional_non_matching_item() async throws {
        // Given
        let orderItem = OrderItem.fake().copy(productID: 3, quantity: 2)
        let orderItem2 = OrderItem.fake().copy(productID: 6, quantity: 1)
        let order = Order.fake().copy(items: [orderItem, orderItem2])
        let sut = [makeCartItem(quantity: 2, matcher: { $0.productID == 3 })]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    private func makeCartItem(id: UUID = UUID(), quantity: Decimal, matching: [OrderItem] = [], matcher: ((OrderItem) -> Bool)? = nil) -> POSCartItem {
        return POSCartItem(item: MockPOSOrderableItem(name: "", id: id, formattedPrice: "", productImageSource: nil, orderItemsToMatch: matching, matcher: matcher),
                           quantity: quantity)
    }
}
