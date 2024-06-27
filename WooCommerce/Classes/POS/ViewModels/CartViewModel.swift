import Combine
import SwiftUI
import protocol Yosemite.POSItem

final class CartViewModel: ObservableObject {
    /// Emits cart items when the CTA is tapped to submit the cart.
    let cartSubmissionPublisher: AnyPublisher<[CartItem], Never>

    /// Emits a signal when the CTA is tapped to update the cart.
    let addMoreToCartPublisher: AnyPublisher<Void, Never>

    @Published private(set) var itemsInCart: [CartItem] = []
    @Published private(set) var orderStage: PointOfSaleDashboardViewModel.OrderStage = .building

    private let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()
    private let addMoreToCartSubject: PassthroughSubject<Void, Never> = .init()

    init(orderStage: AnyPublisher<PointOfSaleDashboardViewModel.OrderStage, Never>) {
        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
        addMoreToCartPublisher = addMoreToCartSubject.eraseToAnyPublisher()
        orderStage.assign(to: &$orderStage)
    }

    var isCartCollapsed: Bool {
        itemsInCart.isEmpty
    }

    var canDeleteItemsFromCart: Bool {
        orderStage != .finalizing
    }

    var itemToScrollToWhenCartUpdated: CartItem? {
        itemsInCart.last
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

    func submitCart() {
        // Q-JC: is this TODO comment still a pending task?
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        cartSubmissionSubject.send(itemsInCart)
    }

    func addMoreToCart() {
        addMoreToCartSubject.send(())
    }
}
