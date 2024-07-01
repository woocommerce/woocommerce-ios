import XCTest
import Combine
@testable import WooCommerce
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class CartViewModelTests: XCTestCase {

    private var orderStageSubject: PassthroughSubject<PointOfSaleDashboardViewModel.OrderStage, Never>!
    private var sut: CartViewModel!

    override func setUp() {
        super.setUp()
        orderStageSubject = PassthroughSubject<PointOfSaleDashboardViewModel.OrderStage, Never>()
        sut = CartViewModel(orderStage: orderStageSubject.eraseToAnyPublisher())
    }

    override func tearDown() {
        orderStageSubject = nil
        sut = nil
        super.tearDown()
    }

    func test_canDeleteItemsFromCart_when_orderStage_is_building_then_returns_true() {
        // Given/When
        XCTAssertEqual(sut.canDeleteItemsFromCart, true, "Initial state")
        orderStageSubject.send(.finalizing)

        // Then
        XCTAssertEqual(sut.canDeleteItemsFromCart, false)
    }

    func test_canDeleteItemsFromCart_when_orderStage_is_finalizing_then_returns_false() {
        // Given/When
        orderStageSubject.send(.finalizing)

        // Then
        XCTAssertEqual(sut.canDeleteItemsFromCart, false)
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

    func test_cart_when_addItemToCart_is_invoked_then_adds_item_to_cart() {
        // Given
        XCTAssertTrue(sut.itemsInCart.isEmpty, "Initial state")
        let item = Self.makeItem()

        // When
        sut.addItemToCart(item)

        // Then
        XCTAssertTrue(sut.itemsInCart.isNotEmpty)
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
        XCTAssertEqual(sut.itemsInCart.map { $0.item.name }, [item, anotherItem].map { $0.name })

        // When
        let firstCartItem = try XCTUnwrap(sut.itemsInCart.first)
        sut.removeItemFromCart(firstCartItem)

        // Then
        XCTAssertEqual(sut.itemsInCart.count, 1)
        XCTAssertEqual(sut.itemsInCart.map { $0.item.name }, [anotherItem.name])
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

    func test_itemsInCartLabel() {
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
