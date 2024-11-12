import Combine
import SwiftUI
@testable import WooCommerce
import protocol Yosemite.POSItem

class MockCartViewModel: CartViewModelProtocol {
    lazy var cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
    let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    lazy var addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
    let addMoreToCartActionSubject: PassthroughSubject<Void, Never> = .init()

    lazy var itemsInCartPublisher: AnyPublisher<[CartItem], Never> = itemsInCartSubject.eraseToAnyPublisher()
    let itemsInCartSubject: PassthroughSubject<[CartItem], Never> = .init()

    var canDeleteItemsFromCart: Bool = false
    var itemsInCartLabel: String? = nil

    func addItemToCart(_ item: any Yosemite.POSItem) {
        addItemToCartCalled = true
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
