import Combine
import SwiftUI
@testable import WooCommerce
import protocol Yosemite.POSItem

class MockCartViewModel: CartViewModelProtocol {
    lazy var cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
    let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    lazy var addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
    let addMoreToCartActionSubject: PassthroughSubject<Void, Never> = .init()

    @Published var itemsInCart: [WooCommerce.CartItem] = []
    var itemsInCartPublisher: Published<[CartItem]>.Publisher { $itemsInCart }

    var canDeleteItemsFromCart: Bool = false
    var itemToScrollToWhenCartUpdated: WooCommerce.CartItem? = nil
    var itemsInCartLabel: String? = nil

    func addItemToCart(_ item: any Yosemite.POSItem) {
        addItemToCartCalled = true
    }

    func removeItemFromCart(_ cartItem: WooCommerce.CartItem) {
        removeItemFromCartCalled = true
    }

    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func submitCart() {
        submitCartCalled = true
    }

    func addMoreToCart() {
        addMoreToCartCalled = true
        addMoreToCartActionSubject.send(())
    }

    // Mock variables
    var addItemToCartCalled = false
    var removeItemFromCartCalled = false
    var removeAllItemsFromCartCalled = false
    var submitCartCalled = false
    var addMoreToCartCalled = false
}

// MARK: - Helpers

extension MockCartViewModel {
    func submitCart(with items: [CartItem]) {
        cartSubmissionSubject.send(items)
        submitCart()
    }
}
