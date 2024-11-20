import Combine
import SwiftUI
@testable import WooCommerce
import protocol Yosemite.POSItem

class MockCartViewModel: CartViewModelProtocol {
    lazy var cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
    let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    var itemsInCartLabel: String? = nil

    func submitCart() {
        submitCartCalled = true
    }

    // Mock variables
    var submitCartCalled = false

    func shouldPreventCartEditing(orderState: PointOfSaleOrderState,
                                  paymentState: PointOfSalePaymentState) -> Bool {
        return false
    }
}

// MARK: - Helpers

extension MockCartViewModel {
    func submitCart(with items: [CartItem]) {
        cartSubmissionSubject.send(items)
        submitCart()
    }
}
