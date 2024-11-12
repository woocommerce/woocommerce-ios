import SwiftUI
import Combine
import protocol Yosemite.POSItem
import protocol WooFoundation.Analytics

final class CartViewModel: CartViewModelProtocol {
    /// Emits cart items when the CTA is tapped to submit the cart.
    let cartSubmissionPublisher: AnyPublisher<[CartItem], Never>
    private let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    /// Emits a signal when the CTA is tapped to update the cart.
    let addMoreToCartActionPublisher: AnyPublisher<Void, Never>
    private let addMoreToCartActionSubject: PassthroughSubject<Void, Never> = .init()

    var itemsInCartPublisher: AnyPublisher<[CartItem], Never> { posModel.$cart.eraseToAnyPublisher() }

    @Published var canDeleteItemsFromCart: Bool = true
    @Published private(set) var shouldShowClearCartButton: Bool = false

    private var analytics: Analytics

    let posModel: PointOfSaleAggregateModel

    init(posModel: PointOfSaleAggregateModel,
         analytics: Analytics) {
        self.posModel = posModel
        self.analytics = analytics

        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
        addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
        assignClearCartButtonVisibility()
    }

    private func assignClearCartButtonVisibility() {
        $canDeleteItemsFromCart
            .combineLatest(posModel.$cart)
            .map { canDelete, itemsInCart in
                return canDelete && itemsInCart.isNotEmpty
            }
            .assign(to: &$shouldShowClearCartButton)
    }

    func addItemToCart(_ item: POSItem) {
        posModel.addToCart(item)
        analytics.track(.pointOfSaleAddItemToCart)
    }

    var itemToScrollToWhenCartUpdated: CartItem?

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

    func addMoreToCart() {
        addMoreToCartActionSubject.send(())
    }
}
