import SwiftUI
import protocol Yosemite.POSItem

final class CartViewModel: ObservableObject {
    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var itemsInCart: [CartItem] = []
    @Published private(set) var orderStage: OrderStage = .building

    init() { }

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
        checkIfCartEmpty()
    }

    func removeAllItemsFromCart() {
        itemsInCart.removeAll()
        checkIfCartEmpty()
    }

    private func checkIfCartEmpty() {
        if itemsInCart.isEmpty {
            orderStage = .building
        }
    }

    func submitCart() {
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        orderStage = .finalizing
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func startNewTransaction() {
        orderStage = .building
    }
}
