import SwiftUI
import Combine
import protocol Yosemite.POSItem
import protocol WooFoundation.Analytics

final class CartViewModel: CartViewModelProtocol {
    var canDeleteItemsFromCart: Bool {
        posModel.orderStage == .building
    }

    var shouldShowClearCartButton: Bool {
        posModel.itemsInCart.isNotEmpty && canDeleteItemsFromCart
    }

    private var analytics: Analytics
    private var posModel: PointOfSaleAggregateModel

    init(analytics: Analytics,
         posModel: PointOfSaleAggregateModel) {
        self.analytics = analytics
        self.posModel = posModel
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        posModel.removeItemFromCart(cartItem)
    }

    func removeAllItemsFromCart() {
        posModel.removeAllItemsFromCart()
    }

    var itemToScrollToWhenCartUpdated: CartItem? {
        posModel.itemsInCart.first
    }

    var itemsInCartLabel: String? {
        switch posModel.itemsInCart.count {
        case 0:
            return nil
        default:
            return String.pluralize(posModel.itemsInCart.count,
                                    singular: "%1$d item",
                                    plural: "%1$d items")
        }
    }

    func submitCart() {
        Task { @MainActor in
            await posModel.submitCart()
        }
    }

    func addMoreToCart() {
        posModel.addMoreToCart()
    }
}
