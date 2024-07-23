import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class CartViewModel: CartViewModelProtocol {
    /// Emits cart items when the CTA is tapped to submit the cart.
    let cartSubmissionPublisher: AnyPublisher<[CartItem], Never>
    private let cartSubmissionSubject: PassthroughSubject<[CartItem], Never> = .init()

    /// Emits a signal when the CTA is tapped to update the cart.
    let addMoreToCartActionPublisher: AnyPublisher<Void, Never>
    private let addMoreToCartActionSubject: PassthroughSubject<Void, Never> = .init()

    @Published private(set) var itemsInCart: [CartItem] = []
    var itemsInCartPublisher: Published<[CartItem]>.Publisher { $itemsInCart }

    // It should be synced with the source of truth in `PointOfSaleDashboardViewModel`.
    @Published private var orderStage: PointOfSaleDashboardViewModel.OrderStage = .building
    private var cancellables = Set<AnyCancellable>()

    var canDeleteItemsFromCart: Bool {
        orderStage != .finalizing
    }

    var isCartEmpty: Bool {
        return itemsInCart.isEmpty
    }

    init(orderStage: AnyPublisher<PointOfSaleDashboardViewModel.OrderStage, Never>) {
        cartSubmissionPublisher = cartSubmissionSubject.eraseToAnyPublisher()
        addMoreToCartActionPublisher = addMoreToCartActionSubject.eraseToAnyPublisher()
    }

    func bind(to orderStagePublisher: AnyPublisher<PointOfSaleDashboardViewModel.OrderStage, Never>) {
        orderStagePublisher
            .assign(to: \.orderStage, on: self)
            .store(in: &cancellables)
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

    var cartLabelColor: Color {
        if itemsInCart.isEmpty {
            Color.posSecondaryTexti3
        } else {
            Color.posPrimaryTexti3
        }
    }

    func submitCart() {
        cartSubmissionSubject.send(itemsInCart)
    }

    func addMoreToCart() {
        addMoreToCartActionSubject.send(())
    }
}
