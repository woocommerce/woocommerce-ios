import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class CartViewModel: ObservableObject {
    /// Emits cart items when the CTA is tapped to submit the cart.
    let cartSubmissionPublisher: AnyPublisher<[CartItem], Never>
    private let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    /// Emits a signal when the CTA is tapped to update the cart.
    let addMoreToCartActionPublisher: AnyPublisher<Void, Never>
    private let addMoreToCartActionSubject: PassthroughSubject<Void, Never> = .init()

    @Published private(set) var itemsInCart: [CartItem] = []

    private let orderStage: PointOfSaleDashboardViewModel.OrderStage = .building

    var canDeleteItemsFromCart: Bool {
        orderStage != .finalizing
    }

    init() {
        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
        addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
    }

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.append(cartItem)
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })
    }

    func removeAllItemsFromCart() {
        itemsInCart.removeAll()
    }

    var itemToScrollToWhenCartUpdated: CartItem? {
        return itemsInCart.last
    }

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
