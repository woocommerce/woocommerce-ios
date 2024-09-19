import Combine
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
import struct Yosemite.Order

final class MockTotalsViewModel: TotalsViewModelProtocol {

    var order: Yosemite.Order?

    @Published var orderState: TotalsViewModel.OrderState = .loaded
    @Published var paymentState: TotalsViewModel.PaymentState = .idle
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectionStatus: CardReaderConnectionStatus = .disconnected
    @Published var startNewOrderAction: Void = ()

    var orderStatePublisher: Published<TotalsViewModel.OrderState>.Publisher { $orderState }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $paymentState }
    var startNewOrderActionPublisher: AnyPublisher<Void, Never> { $startNewOrderAction.eraseToAnyPublisher() }

    var isSyncingOrder: Bool {
        return orderState.isSyncing
    }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? {
        // Provide a mock implementation if needed
        nil
    }

    func startNewOrder() {
        paymentState = .acceptingCard
    }

    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        orderState = .syncing
    }

    var spyStopShowingTotalsViewCalled = false
    func stopShowingTotalsView() {
        spyStopShowingTotalsViewCalled = true
    }

    var spyStartShowingTotalsViewCalled = false
    func startShowingTotalsView() {
        spyStartShowingTotalsViewCalled = true
    }
}
