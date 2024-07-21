import Combine
import Yosemite

class AnyTotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    @Published private var _isSyncingOrder: Bool
    @Published private var _paymentState: TotalsViewModel.PaymentState
    @Published var showsCardReaderSheet: Bool
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent
    @Published var connectionStatus: CardReaderConnectionStatus

    // Wrapping the computed properties
    @Published private var _formattedCartTotalPrice: String?
    @Published private var _formattedOrderTotalPrice: String?
    @Published private var _formattedOrderTotalTaxPrice: String?

    var isSyncingOrderPublisher: Published<Bool>.Publisher { $_isSyncingOrder }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $_paymentState }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { $showsCardReaderSheet }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $_formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $_formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $_formattedOrderTotalTaxPrice }

    private var wrapped: any TotalsViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    init(_ wrapped: any TotalsViewModelProtocol) {
        self.wrapped = wrapped
        self._isSyncingOrder = wrapped.isSyncingOrder
        self._paymentState = wrapped.paymentState
        self.showsCardReaderSheet = wrapped.showsCardReaderSheet
        self.cardPresentPaymentAlertViewModel = wrapped.cardPresentPaymentAlertViewModel
        self.cardPresentPaymentEvent = wrapped.cardPresentPaymentEvent
        self.connectionStatus = wrapped.connectionStatus
        self._formattedCartTotalPrice = wrapped.formattedCartTotalPrice
        self._formattedOrderTotalPrice = wrapped.formattedOrderTotalPrice
        self._formattedOrderTotalTaxPrice = wrapped.formattedOrderTotalTaxPrice

        bindPublishers()
    }

    private func bindPublishers() {
        wrapped.isSyncingOrderPublisher
            .assign(to: \._isSyncingOrder, on: self)
            .store(in: &cancellables)
        wrapped.paymentStatePublisher
            .assign(to: \._paymentState, on: self)
            .store(in: &cancellables)
        wrapped.showsCardReaderSheetPublisher
            .assign(to: \.showsCardReaderSheet, on: self)
            .store(in: &cancellables)
        wrapped.cardPresentPaymentAlertViewModelPublisher
            .assign(to: \.cardPresentPaymentAlertViewModel, on: self)
            .store(in: &cancellables)
        wrapped.cardPresentPaymentEventPublisher
            .assign(to: \.cardPresentPaymentEvent, on: self)
            .store(in: &cancellables)
        wrapped.connectionStatusPublisher
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
        wrapped.formattedCartTotalPricePublisher
            .assign(to: \._formattedCartTotalPrice, on: self)
            .store(in: &cancellables)
        wrapped.formattedOrderTotalPricePublisher
            .assign(to: \._formattedOrderTotalPrice, on: self)
            .store(in: &cancellables)
        wrapped.formattedOrderTotalTaxPricePublisher
            .assign(to: \._formattedOrderTotalTaxPrice, on: self)
            .store(in: &cancellables)
    }

    var isSyncingOrder: Bool {
        get { _isSyncingOrder }
        set {
            _isSyncingOrder = newValue
            wrapped.isSyncingOrder = newValue
        }
    }

    var paymentState: TotalsViewModel.PaymentState {
        get { _paymentState }
        set {
            _paymentState = newValue
            wrapped.paymentState = newValue
        }
    }

    var isShimmering: Bool {
        wrapped.isShimmering
    }

    var isPriceFieldRedacted: Bool {
        wrapped.isPriceFieldRedacted
    }

    var isSubtotalFieldRedacted: Bool {
        wrapped.isSubtotalFieldRedacted
    }

    var isTaxFieldRedacted: Bool {
        wrapped.isTaxFieldRedacted
    }

    var isTotalPriceFieldRedacted: Bool {
        wrapped.isTotalPriceFieldRedacted
    }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? {
        wrapped.cardPresentPaymentInlineMessage
    }

    var showRecalculateButton: Bool {
        wrapped.showRecalculateButton
    }

    var order: Order? {
        wrapped.order
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
        wrapped.startSyncingOrder(with: cartItems, allItems: allItems)
    }

    func startNewTransaction() {
        wrapped.startNewTransaction()
    }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        wrapped.calculateAmountsTapped(with: cartItems, allItems: allItems)
    }

    func cardPaymentTapped() {
        wrapped.cardPaymentTapped()
    }

    func onTotalsViewDisappearance() {
        wrapped.onTotalsViewDisappearance()
    }

    // Computed properties for formatted prices
    var formattedCartTotalPrice: String? {
        wrapped.formattedCartTotalPrice
    }

    var formattedOrderTotalPrice: String? {
        wrapped.formattedOrderTotalPrice
    }

    var formattedOrderTotalTaxPrice: String? {
        wrapped.formattedOrderTotalTaxPrice
    }
}
