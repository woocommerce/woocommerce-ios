import XCTest
import Combine
import SwiftUI
@testable import WooCommerce
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class CartViewModelTests: XCTestCase {

    private var sut: CartViewModel!
    private var analytics: WooAnalytics!
    private var analyticsProvider: MockAnalyticsProvider!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = CartViewModel(analytics: analytics)
    }

    override func tearDown() {
        analyticsProvider = nil
        analytics = nil
        sut = nil
        super.tearDown()
    }

    func test_cart_when_submitCart_is_invoked_then_cartSubmissionPublisher_emits_cart_items() {
        // Given
        var cancellables: Set<AnyCancellable> = []
        let item = Self.makeItem()
        let anotherItem = Self.makeItem()

        // When
        sut.addItemToCart(item)
        sut.addItemToCart(anotherItem)
        sut.cartSubmissionPublisher.sink(receiveValue: { cartItems in
            // Then
            XCTAssertEqual(cartItems.count, 2)
        })
        .store(in: &cancellables)

        sut.submitCart()
    }

    func test_addItemToCart_then_cart_is_not_empty() {
        // Given
        XCTAssertTrue(sut.itemsInCart.isEmpty, "Initial state")
        let item = Self.makeItem()

        // When
        sut.addItemToCart(item)

        // Then
        XCTAssertTrue(sut.itemsInCart.isNotEmpty)
    }

    func test_addItemToCart_when_multiple_items_added_then_latest_item_is_first() {
        // Given
        XCTAssertTrue(sut.itemsInCart.isEmpty, "Initial state")
        let items = [Self.makeItem(), Self.makeItem(), Self.makeItem()]

        // When
        items.forEach(sut.addItemToCart)

        // Then
        XCTAssertEqual(sut.itemsInCart.map(\.item.itemID), items.reversed().map(\.itemID))
        XCTAssertNotEqual(sut.itemsInCart.map(\.item.itemID), items.map(\.itemID))
    }

    func test_removeItemFromCart() {
        /* TODO:
         https://github.com/woocommerce/woocommerce-ios/issues/13209
         The unique UUID for CartItem is set on init, but CartItem is only internal to addItemToCart()
         We need to extract this to a separate function and assure that ID's are correct,
         otherwise the UUID's for testing won't match
         */
    }

    func test_removeItemFromCart_after_adding_2_items_removes_item() throws {
        // Given
        let item = Self.makeItem(name: "Item 1")
        let anotherItem = Self.makeItem(name: "Item 2")
        sut.addItemToCart(item)
        sut.addItemToCart(anotherItem)
        XCTAssertEqual(sut.itemsInCart.count, 2)
        XCTAssertEqual(sut.itemsInCart.map { $0.item.name }, [anotherItem, item].map { $0.name })

        // When
        let firstCartItem = try XCTUnwrap(sut.itemsInCart.first)
        sut.removeItemFromCart(firstCartItem)

        // Then
        XCTAssertEqual(sut.itemsInCart.count, 1)
        XCTAssertEqual(sut.itemsInCart.map { $0.item.name }, [item.name])
    }

    func test_cart_when_removeAllItemsFromCart_is_invoked_then_removes_all_items_from_cart() {
        // Given
        let item = Self.makeItem()
        let anotherItem = Self.makeItem()

        sut.addItemToCart(item)
        sut.addItemToCart(anotherItem)
        XCTAssertEqual(sut.itemsInCart.count, 2)

        // When
        sut.removeAllItemsFromCart()

        // Then
        XCTAssertEqual(sut.itemsInCart.count, 0)
    }

    func test_cart_when_itemToScrollToWhenCartUpdated_is_invoked_then_returns_the_last_cart_item() {
        // Given
        let firstItem = Self.makeItem()
        let lastItem = Self.makeItem()

        sut.addItemToCart(firstItem)
        sut.addItemToCart(lastItem)

        guard let expectedItem = sut.itemToScrollToWhenCartUpdated else {
            return XCTFail("Expected item, found nil.")
        }

        // Then
        XCTAssertEqual(expectedItem.item.itemID, lastItem.itemID)
    }

    func test_itemsInCartLabel_when_addItemToCart_then_label_updates_accordingly() {
        XCTAssertNil(sut.itemsInCartLabel, "Initial state")

        // Given
        let anItem = Self.makeItem()
        let anotherItem = Self.makeItem()

        // When/Then
        sut.addItemToCart(anItem)
        XCTAssertEqual(sut.itemsInCartLabel, "1 item")

        sut.addItemToCart(anotherItem)
        XCTAssertEqual(sut.itemsInCartLabel, "2 items")
    }

    func test_isCartEmpty() {
        // Given
        let item = Self.makeItem()
        XCTAssertTrue(sut.isCartEmpty)

        // When
        sut.addItemToCart(item)

        // Then
        XCTAssertFalse(sut.isCartEmpty)
    }

    func test_shouldShowClearCartButton_before_addItemToCart_and_deletion_allowed_false() {
        // Given
        sut.canDeleteItemsFromCart = true

        // When/Then
        XCTAssertFalse(sut.shouldShowClearCartButton)
    }

    func test_shouldShowClearCartButton_when_addItemToCart_and_deletion_allowed_true() {
        XCTAssertFalse(sut.shouldShowClearCartButton, "Initial state")

        // Given
        sut.canDeleteItemsFromCart = true
        let anItem = Self.makeItem()

        // When/Then
        sut.addItemToCart(anItem)

        // Then
        XCTAssertTrue(sut.shouldShowClearCartButton)
    }

    func test_shouldShowClearCartButton_when_addItemToCart_and_deletion_disallowed_false() {
        XCTAssertFalse(sut.shouldShowClearCartButton, "Initial state")

        // Given
        sut.canDeleteItemsFromCart = false
        let anItem = Self.makeItem()

        // When/Then
        sut.addItemToCart(anItem)

        // Then
        XCTAssertFalse(sut.shouldShowClearCartButton)
    }

    func test_receivedEvents_when_addItemToCart_then_tracks_pos_item_added_to_cart_event() {
        // Given
        let expectedEvent = "pos_item_added_to_cart"
        let item = Self.makeItem()

        // When
        sut.addItemToCart(item)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, expectedEvent)
    }
}

private extension CartViewModelTests {
    static func makeItem(name: String = "") -> POSItem {
        return POSProduct(itemID: UUID(),
                          productID: 0,
                          name: name,
                          price: "",
                          formattedPrice: "",
                          itemCategories: [],
                          productImageSource: nil,
                          productType: .simple)
    }
}
