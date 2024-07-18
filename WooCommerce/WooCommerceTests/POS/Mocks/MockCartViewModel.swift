import Combine
@testable import WooCommerce

class MockCartViewModel: ObservableObject {
    let cartViewModel: CartViewModel
    private let cartSubmissionSubject = PassthroughSubject<[CartItem], Never>()

    var cartSubmissionPublisher: AnyPublisher<[CartItem], Never> {
        cartSubmissionSubject.eraseToAnyPublisher()
    }

    init(orderStage: AnyPublisher<PointOfSaleDashboardViewModel.OrderStage, Never>) {
        self.cartViewModel = CartViewModel(orderStage: orderStage)
    }

//    var itemsInCart: [CartItem] {
//        get { cartViewModel.itemsInCart }
//        set { cartViewModel.itemsInCart = newValue }
//    }
//
//    var itemToScrollToWhenCartUpdated: CartItem? {
//        cartViewModel.itemToScrollToWhenCartUpdated
//    }
//
//    var itemsInCartLabel: String? {
//        cartViewModel.itemsInCartLabel
//    }
//
//    func addItemToCart(_ item: POSItem) {
//        cartViewModel.addItemToCart(item)
//    }

//    func removeItemFromCart(_ cartItem: CartItem) {
//        cartViewModel.removeItemFromCart(cartItem)
//    }
//
//    func removeAllItemsFromCart() {
//        cartViewModel.removeAllItemsFromCart()
//    }

    func submitCart(with items: [CartItem]) {
        cartSubmissionSubject.send(items)
    }

//    func addMoreToCart() {
//        cartViewModel.addMoreToCart()
//    }
}
