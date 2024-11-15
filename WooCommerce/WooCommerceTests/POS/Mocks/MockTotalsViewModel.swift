import Combine
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
import struct Yosemite.Order

final class MockTotalsViewModel: TotalsViewModelProtocol {

    @Published var paymentState: TotalsViewModel.PaymentState = .idle

    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    @Published var editOrderAction: Void = ()

    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $paymentState }
    var editOrderActionPublisher: AnyPublisher<Void, Never> { $editOrderAction.eraseToAnyPublisher() }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? {
        // Provide a mock implementation if needed
        nil
    }

    func startNewOrder() {
        paymentState = .acceptingCard
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
