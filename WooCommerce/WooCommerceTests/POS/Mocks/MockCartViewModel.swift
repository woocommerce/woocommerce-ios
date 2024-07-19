import Combine
@testable import WooCommerce

class MockCartViewModel: ObservableObject {
    let cartViewModel: CartViewModel<MockTotalsViewModel>
    private let cartSubmissionSubject = PassthroughSubject<[CartItem], Never>()

    var cartSubmissionPublisher: AnyPublisher<[CartItem], Never> {
        cartSubmissionSubject.eraseToAnyPublisher()
    }

    init(orderStage: AnyPublisher<PointOfSaleDashboardViewModel<MockTotalsViewModel>.OrderStage, Never>) {
        self.cartViewModel = CartViewModel<MockTotalsViewModel>(orderStage: orderStage)
    }

    func submitCart(with items: [CartItem]) {
        cartSubmissionSubject.send(items)
        cartViewModel.submitCart()
    }
}
