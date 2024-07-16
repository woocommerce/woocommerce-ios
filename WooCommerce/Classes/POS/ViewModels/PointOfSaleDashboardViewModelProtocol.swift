import Combine

protocol PointOfSaleDashboardViewModelProtocol: ObservableObject {
    func simulateOrderSyncing(cartItems: [CartItem])
}
