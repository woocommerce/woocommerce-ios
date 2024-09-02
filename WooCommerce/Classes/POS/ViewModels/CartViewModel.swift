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

    @Published private(set) var itemsInCart: [CartItem] = []
    var itemsInCartPublisher: Published<[CartItem]>.Publisher { $itemsInCart }

    @Published var canDeleteItemsFromCart: Bool = true
    @Published private(set) var shouldShowClearCartButton: Bool = false

    var isCartEmpty: Bool {
        return itemsInCart.isEmpty
    }

    private var analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics

        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
        addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
        assignClearCartButtonVisibility()
    }

    private func assignClearCartButtonVisibility() {
        $canDeleteItemsFromCart
            .combineLatest($itemsInCart)
            .map { canDelete, itemsInCart in
                return canDelete && itemsInCart.isNotEmpty
            }
            .assign(to: &$shouldShowClearCartButton)
    }

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.insert(cartItem, at: 0)
        itemToScrollToWhenCartUpdated = cartItem

        analytics.track(.pointOfSaleAddItemToCart)
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })
    }

    func removeAllItemsFromCart() {
        itemsInCart.removeAll()
    }

    var itemToScrollToWhenCartUpdated: CartItem?

    var itemsInCartLabel: String? {
        switch itemsInCart.count {
        case 0:
            return nil
        default:
            return String.pluralize(itemsInCart.count,
                                    singular: "%1$d item",
                                    plural: "%1$d items")
        }
    }

    func submitCart() {
        cartSubmissionSubject.send(itemsInCart)
    }

    func addMoreToCart() {
        addMoreToCartActionSubject.send(())
    }
}
