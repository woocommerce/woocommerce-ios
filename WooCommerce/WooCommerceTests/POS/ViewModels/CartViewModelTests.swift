import XCTest
import Combine
import SwiftUI
@testable import WooCommerce
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class CartViewModelTests: XCTestCase {

    private var sut: CartViewModel!

    override func setUp() {
        super.setUp()
        sut = CartViewModel(posModel: PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider()))
    }

    override func tearDown() {
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

    func test_removeItemFromCart() {
        /* TODO:
         https://github.com/woocommerce/woocommerce-ios/issues/13209
         The unique UUID for CartItem is set on init, but CartItem is only internal to addItemToCart()
         We need to extract this to a separate function and assure that ID's are correct,
         otherwise the UUID's for testing won't match
         */
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
