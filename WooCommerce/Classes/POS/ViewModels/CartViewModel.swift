import SwiftUI
import protocol Yosemite.POSItem

final class CartViewModel: ObservableObject {
    @Published private(set) var itemsInCart: [CartItem] = []
    // TODO: Move order stage here as well
    // @Published private(set) var orderStage: OrderStage = .building

    init() { }

    var isEmpty: Bool {
        itemsInCart.isEmpty
    }

    var isCartCollapsed: Bool {
        itemsInCart.isEmpty
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
}
