import Combine
import struct Yosemite.Order
import protocol Yosemite.POSItem

protocol TotalsViewModelProtocol {
    var paymentState: TotalsViewModel.PaymentState { get }
    var connectionStatus: CardPresentPaymentReaderConnectionStatus { get }

    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { get }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }

    func startNewOrder()

    func startShowingTotalsView()
    func stopShowingTotalsView()
}
