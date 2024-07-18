import Combine
import Yosemite

protocol TotalsViewModelProtocol {
    var isSyncingOrder: Bool { get set }
    var paymentState: TotalsViewModel.PaymentState { get set }
    var showsCardReaderSheet: Bool { get set }
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? { get set }
    var cardPresentPaymentEvent: CardPresentPaymentEvent { get set }
    var connectionStatus: CardReaderConnectionStatus { get set }
    var formattedCartTotalPrice: String? { get set }
    var formattedOrderTotalPrice: String? { get set }
    var formattedOrderTotalTaxPrice: String? { get set }

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
    var isPriceFieldRedacted: Bool { get }
    var isTotalPriceFieldRedacted: Bool { get }
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var showRecalculateButton: Bool { get }
    var order: POSOrder? { get }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem])
    func startNewTransaction()
    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem])
    func cardPaymentTapped()
    func onTotalsViewDisappearance()
}
