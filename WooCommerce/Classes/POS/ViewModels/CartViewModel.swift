import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class CartViewModel: CartViewModelProtocol {
    /// Emits cart items when the CTA is tapped to submit the cart.
    let cartSubmissionPublisher: AnyPublisher<[CartItem], Never>
    private let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    let posModel: PointOfSaleAggregateModel

    init(posModel: PointOfSaleAggregateModel) {
        self.posModel = posModel

        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
    }

    var itemsInCartLabel: String? {
        let itemsCount = posModel.cart.count
        guard itemsCount > 0 else {
            return nil
        }
        return String.pluralize(itemsCount,
                                singular: "%1$d item",
                                plural: "%1$d items")
    }

    func submitCart() {
        cartSubmissionSubject.send(posModel.cart)
    }
}
