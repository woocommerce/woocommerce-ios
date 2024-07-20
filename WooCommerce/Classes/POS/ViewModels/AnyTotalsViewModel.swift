import Combine
import Yosemite

class AnyTotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    @Published private var _isSyncingOrder: Bool
    @Published private var _paymentState: TotalsViewModel.PaymentState
    @Published var showsCardReaderSheet: Bool
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent
    @Published var connectionStatus: CardReaderConnectionStatus
    @Published var formattedCartTotalPrice: String?
    @Published var formattedOrderTotalPrice: String?
    @Published var formattedOrderTotalTaxPrice: String?

    var isSyncingOrderPublisher: Published<Bool>.Publisher { $_isSyncingOrder }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $_paymentState }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { $showsCardReaderSheet }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $formattedOrderTotalTaxPrice }

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
        self.formattedCartTotalPrice = wrapped.formattedCartTotalPrice
        self.formattedOrderTotalPrice = wrapped.formattedOrderTotalPrice
        self.formattedOrderTotalTaxPrice = wrapped.formattedOrderTotalTaxPrice

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
            .assign(to: \.formattedCartTotalPrice, on: self)
            .store(in: &cancellables)
        wrapped.formattedOrderTotalPricePublisher
            .assign(to: \.formattedOrderTotalPrice, on: self)
            .store(in: &cancellables)
        wrapped.formattedOrderTotalTaxPricePublisher
            .assign(to: \.formattedOrderTotalTaxPrice, on: self)
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

    var isTotalPriceFieldRedacted: Bool {
        wrapped.isTotalPriceFieldRedacted
    }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? {
        wrapped.cardPresentPaymentInlineMessage
    }

    var showRecalculateButton: Bool {
        wrapped.showRecalculateButton
    }

    var order: POSOrder? {
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
}
