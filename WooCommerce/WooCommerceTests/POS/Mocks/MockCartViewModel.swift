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

    func submitCart(with items: [CartItem]) {
        cartSubmissionSubject.send(items)
    }
}
