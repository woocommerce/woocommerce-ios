import SwiftUI
import Combine
import protocol Yosemite.POSItem

protocol CartViewModelProtocol: ObservableObject {
    var itemToScrollToWhenCartUpdated: CartItem? { get }
    var itemsInCartLabel: String? { get }

    func addItemToCart(_ item: POSItem)
    func removeItemFromCart(_ cartItem: CartItem)
    func removeAllItemsFromCart()
    func submitCart()
    func addMoreToCart()
}
