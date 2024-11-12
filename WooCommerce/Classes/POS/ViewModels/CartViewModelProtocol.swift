import SwiftUI
import Combine
import protocol Yosemite.POSItem

protocol CartViewModelProtocol: ObservableObject {
    var cartSubmissionPublisher: AnyPublisher<[CartItem], Never> { get }
    var addMoreToCartActionPublisher: AnyPublisher<Void, Never> { get }

    var canDeleteItemsFromCart: Bool { get set }

    var itemsInCartLabel: String? { get }
    var itemsInCartPublisher: AnyPublisher<[CartItem], Never> { get }

    func addItemToCart(_ item: POSItem)
    func submitCart()
    func addMoreToCart()
}
