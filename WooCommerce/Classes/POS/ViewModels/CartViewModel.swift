import SwiftUI
import Combine
import protocol Yosemite.POSItem
import protocol WooFoundation.Analytics

final class CartViewModel: CartViewModelProtocol {
    var canDeleteItemsFromCart: Bool {
        posModel.orderStage == .building
    }

    var shouldShowClearCartButton: Bool {
        posModel.cart.isNotEmpty && canDeleteItemsFromCart
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
        posModel.cart.first
    }

    var itemsInCartLabel: String? {
        switch posModel.cart.count {
        case 0:
            return nil
        default:
            return String.pluralize(posModel.cart.count,
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
