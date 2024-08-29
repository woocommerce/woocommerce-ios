import SwiftUI
import Combine
import protocol Yosemite.POSItem

protocol CartViewModelProtocol: ObservableObject {
    var cartSubmissionPublisher: AnyPublisher<[CartItem], Never> { get }
    var addMoreToCartActionPublisher: AnyPublisher<Void, Never> { get }
    var itemsInCart: [CartItem] { get }
    var canDeleteItemsFromCart: Bool { get set }
    var itemToScrollToWhenCartUpdated: CartItem? { get }
    var itemsInCartLabel: String? { get }
    var itemsInCartPublisher: Published<[CartItem]>.Publisher { get }

    func addItemToCart(_ item: POSItem)
    func removeItemFromCart(_ cartItem: CartItem)
    func removeAllItemsFromCart()
    func submitCart()
    func addMoreToCart()
}
