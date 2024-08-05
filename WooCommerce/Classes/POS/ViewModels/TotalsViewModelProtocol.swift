import Combine
import struct Yosemite.Order
import protocol Yosemite.POSItem

protocol TotalsViewModelProtocol {
    var isSyncingOrder: Bool { get }
    var paymentState: TotalsViewModel.PaymentState { get }
    var showsCardReaderSheet: Bool { get set }
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? { get }
    var cardPresentPaymentEvent: CardPresentPaymentEvent { get }
    var connectionStatus: CardReaderConnectionStatus { get }
    var formattedCartTotalPrice: String? { get }
    var formattedOrderTotalPrice: String? { get }
    var formattedOrderTotalTaxPrice: String? { get }

    var isSyncingOrderPublisher: Published<Bool>.Publisher { get }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { get }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { get }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { get }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { get }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { get }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { get }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { get }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { get }


    var isShimmering: Bool { get }
    var isTotalPriceFieldRedacted: Bool { get }
    var isSubtotalFieldRedacted: Bool { get }
    var isTaxFieldRedacted: Bool { get }
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var showRecalculateButton: Bool { get }
    var order: Order? { get }

    func startNewTransaction()
    func cardPaymentTapped()
    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem])
    func onTotalsViewDisappearance()
}
