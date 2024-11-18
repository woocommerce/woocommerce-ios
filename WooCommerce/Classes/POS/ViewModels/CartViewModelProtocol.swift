import SwiftUI
import Combine
import protocol Yosemite.POSItem

protocol CartViewModelProtocol: ObservableObject {
    var cartSubmissionPublisher: AnyPublisher<[CartItem], Never> { get }

    var itemsInCartLabel: String? { get }

    func submitCart()
}
