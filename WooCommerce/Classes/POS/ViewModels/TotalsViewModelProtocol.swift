import Combine
import struct Yosemite.Order
import protocol Yosemite.POSItem

protocol TotalsViewModelProtocol {
    var paymentState: TotalsViewModel.PaymentState { get }
    var cardPresentPaymentEvent: CardPresentPaymentEvent { get }
    var connectionStatus: CardPresentPaymentReaderConnectionStatus { get }

    var orderStatePublisher: Published<TotalsViewModel.OrderState>.Publisher { get }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { get }
    var startNewOrderActionPublisher: AnyPublisher<Void, Never> { get }
    var editOrderActionPublisher: AnyPublisher<Void, Never> { get }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var order: Order? { get }

    func startNewOrder()
    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem])

    func startShowingTotalsView()
    func stopShowingTotalsView()
}
