import SwiftUI
import Combine
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCartItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    enum PaymentState {
        case idle
        case acceptingCard
        case validatingOrder
        case validatingOrderError
        case preparingReader
        case processingPayment
        case paymentError
        case cardPaymentSuccessful
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published private(set) var isShowingCardReaderStatus: Bool = false
    @Published private(set) var isShowingTotalsFields: Bool = false

    @Published private(set) var order: Order? = nil
    private var totalsCalculator: OrderTotalsCalculator? = nil
    @Published private(set) var orderState: OrderState = .idle

    @Published private(set) var paymentState: PaymentState

    @Published private(set) var connectionStatus: CardReaderConnectionStatus = .disconnected

    @Published var formattedCartTotalPrice: String?
    @Published var formattedOrderTotalPrice: String?
    @Published var formattedOrderTotalTaxPrice: String?

    private let startNewOrderActionSubject = PassthroughSubject<Void, Never>()
    var startNewOrderActionPublisher: AnyPublisher<Void, Never> {
        startNewOrderActionSubject.eraseToAnyPublisher()
    }

    var computedFormattedCartTotalPrice: String? {
        formattedPrice(totalsCalculator?.itemsTotal.stringValue, currency: order?.currency)
    }

    var computedFormattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var computedFormattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var isShimmering: Bool {
        orderState.isSyncing
    }

    var isSubtotalFieldRedacted: Bool {
        formattedCartTotalPrice == nil || orderState.isSyncing
    }

    var isTaxFieldRedacted: Bool {
        formattedOrderTotalTaxPrice == nil || orderState.isSyncing
    }

    var isTotalPriceFieldRedacted: Bool {
        formattedOrderTotalPrice == nil || orderState.isSyncing
    }

    private let orderService: POSOrderServiceProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let currencyFormatter: CurrencyFormatter

    init(orderService: POSOrderServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         currencyFormatter: CurrencyFormatter,
         paymentState: PaymentState) {
        self.orderService = orderService
        self.cardPresentPaymentService = cardPresentPaymentService
        self.currencyFormatter = currencyFormatter
        self.paymentState = paymentState
        self.formattedCartTotalPrice = nil
        self.formattedOrderTotalPrice = nil
        self.formattedOrderTotalTaxPrice = nil

        // Initialize all properties before calling methods
        self.observeConnectedReaderForStatus()
        self.observeCardPresentPaymentEvents()
    }

    var orderStatePublisher: Published<OrderState>.Publisher { $orderState }
    var paymentStatePublisher: Published<PaymentState>.Publisher { $paymentState }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { $showsCardReaderSheet }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $formattedOrderTotalTaxPrice }

    private var startPaymentOnReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        Task { @MainActor in
            await startSyncingOrder(with: cartItems, allItems: allItems)
        }
    }

    private func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) async {
        guard CartItem.areOrderAndCartDifferent(order: order, cartItems: cartItems) else {
            await startPaymentWhenReaderConnected()
            return
        }
        // calculate totals and sync order if there was a change in the cart
        await syncOrder(for: cartItems, allItems: allItems)
    }

    func connectReaderTapped() {
        Task { @MainActor in
            do {
                let _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
        }
    }

    func startNewOrder() {
        paymentState = .acceptingCard
        clearOrder()
        cardPresentPaymentInlineMessage = nil
        startNewOrderActionSubject.send(())
    }

    func onTotalsViewDisappearance() {
        // This is a backup – it's not called until transitions are complete when using the back button.
        // The delay can lead to race conditions with tapping a card.
        // It's likely that the payment will already have been cancelled due to the change of orderStage.
        cancelReaderPreparation()
    }

    func startShowingTotalsView() {
        observeReaderReconnection()
    }

    func stopShowingTotalsView() {
        cancelReaderPreparation()
    }

    private func cancelReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        startPaymentOnReaderConnection?.cancel()
        cardReaderDisconnection?.cancel()
    }
}

// MARK: - Order syncing

extension TotalsViewModel {
    @MainActor
    func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard orderState.isSyncing == false else {
            return
        }
        orderState = .syncing
        let cart = cartProducts.map {
            POSCartItem(itemID: nil, product: $0.item, quantity: Decimal($0.quantity))
        }

        do {
            let syncedOrder = try await orderService.syncOrder(cart: cart, order: order, allProducts: allItems)
            self.updateOrder(syncedOrder)
            orderState = .loaded
            await startPaymentWhenReaderConnected()
            DDLogInfo("🟢 [POS] Synced order: \(syncedOrder)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")

            // Consider removing error or handle specific errors with our own formatting and localization
            orderState = .error(.init(message: error.localizedDescription, handler: { [weak self] in
                Task {
                    await self?.syncOrder(for: cartProducts, allItems: allItems)
                }
            }))
        }
    }

    private func updateFormattedPrices() {
        formattedCartTotalPrice = computedFormattedCartTotalPrice
        formattedOrderTotalPrice = computedFormattedOrderTotalPrice
        formattedOrderTotalTaxPrice = computedFormattedOrderTotalTaxPrice
    }

    private func updateOrder(_ updatedOrder: Order) {
        self.order = updatedOrder
        totalsCalculator = OrderTotalsCalculator(for: updatedOrder, using: currencyFormatter)
        updateFormattedPrices()
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }
}

extension TotalsViewModel {
    func clearOrder() {
        order = nil
    }
}

// MARK: - Payment collection

private extension TotalsViewModel {
    @MainActor
    func collectPayment() async {
        guard let order else {
            return
        }
        do {
            try await collectPayment(for: order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    @MainActor
    func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
    }
}

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.connectedReaderPublisher
            .map { connectedReader in
                // Note that this does not cover when a reader is disconnecting
                connectedReader == nil ? .disconnected: .connected
            }
            .assign(to: &$connectionStatus)

        Publishers.CombineLatest4($connectionStatus, $orderState, $cardPresentPaymentInlineMessage, $order)
            .map { connectionStatus, orderState, message, order in
                guard order != nil,
                      orderState.isLoaded
                        else {
                    // When the order's being created or synced, we only show the shimmering totals.
                    // Before the order exists, we don’t want to show the card payment status, as it will
                    // show for a second initially, then disappear the moment we start syncing the order.
                    return false
                }

                switch connectionStatus {
                case .connected, .disconnecting:
                    return message != nil
                case .disconnected:
                    // Since the reader is disconnected, this will show the "Connect your reader" CTA button view.
                    return true
                }
            }
            .assign(to: &$isShowingCardReaderStatus)
    }

    func observeReaderReconnection() {
        cardReaderDisconnection = $connectionStatus
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPaymentWhenReaderConnected()
                }
            }
    }

    func startPaymentWhenReaderConnected() async {
        guard connectionStatus == .connected else {
            return startPaymentOnReaderConnection = $connectionStatus.filter { $0 == .connected }
                .removeDuplicates()
                .sink { _ in
                    Task { @MainActor [weak self] in
                        await self?.collectPayment()
                    }
                }
        }
        await collectPayment()
    }

    func observeCardPresentPaymentEvents() {
        cardPresentPaymentService.paymentEventPublisher.assign(to: &$cardPresentPaymentEvent)
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentAlertType? in
                guard let self else { return nil }
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = presentationStyle(for: eventDetails)
                else {
                    return nil
                }
                return alertType
            }
            .assign(to: &$cardPresentPaymentAlertViewModel)
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .assign(to: &$cardPresentPaymentInlineMessage)
        cardPresentPaymentService.paymentEventPublisher.map { [weak self] event in
            guard let self else { return false }
            switch event {
            case .idle:
                return false
            case .show(let eventDetails):
                switch presentationStyle(for: eventDetails) {
                case .alert:
                    return true
                case .message, .none:
                    return false
                }
            case .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent in
                guard let self else { return .none }
                return PaymentState(from: paymentEvent,
                                    using: presentationStyleDeterminerDependencies) }
            .assign(to: &$paymentState)

        paymentStatePublisher
            .map { paymentState in
                switch paymentState {
                case .idle,
                        .acceptingCard,
                        .validatingOrder,
                        .validatingOrderError,
                        .preparingReader:
                    return true
                case .processingPayment,
                        .paymentError,
                        .cardPaymentSuccessful:
                    return false
                }
            }
            .assign(to: &$isShowingTotalsFields)
    }
}

private extension TotalsViewModel {
    /// Maps PaymentEvent to POSMessageType and annonates additional information if necessary
    /// - Parameter event: CardPresentPaymentEvent
    /// - Returns: PointOfSaleCardPresentPaymentMessageType
    func mapCardPresentPaymentEventToMessageType(_ event: CardPresentPaymentEvent) -> PointOfSaleCardPresentPaymentMessageType? {
        guard case let .show(eventDetails) = event,
              case let .message(messageType) = presentationStyle(for: eventDetails) else {
            return nil
        }

        return messageType
    }

    func presentationStyle(for eventDetails: CardPresentPaymentEventDetails) -> PointOfSaleCardPresentPaymentEventPresentationStyle? {
        PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: presentationStyleDeterminerDependencies)
    }

    var presentationStyleDeterminerDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies {
        let cancelThenCollectPaymentWithWeakSelf: () -> Void = { [weak self] in
            self?.cancelThenCollectPayment()
        }

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentWithWeakSelf,
            nonRetryableErrorExitAction: cancelThenCollectPaymentWithWeakSelf,
            formattedOrderTotalPrice: formattedOrderTotalPrice,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentWithWeakSelf,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.startNewOrder()
            })
    }

    func cancelThenCollectPayment() {
        cardPresentPaymentService.cancelPayment()
        Task { [weak self] in
            await self?.collectPayment()
        }
    }
}

private extension TotalsViewModel.PaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent,
          using paymentEventPresentationStyleDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies) {
        switch cardPaymentEvent {
        case .idle:
            self = .idle
        case .show(.validatingOrder):
            self = .validatingOrder
        case .show(.preparingForPayment):
            self = .preparingReader
        case .show(.tapSwipeOrInsertCard):
            self = .acceptingCard
        case .show(.processing),
                .show(.displayReaderMessage):
            self = .processingPayment
        case .show(.paymentError):
            if case let .show(eventDetails) = cardPaymentEvent,
               case let .message(messageType) = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: paymentEventPresentationStyleDependencies),
               case .validatingOrderError = messageType {
                self = .validatingOrderError
            } else {
                self = .paymentError
            }
        case .show(.paymentCaptureError):
            self = .paymentError
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        default:
            return nil
        }
    }
}

// MARK: - Order State

extension TotalsViewModel {
    enum OrderState: Equatable {
        case idle
        case syncing
        case loaded
        case error(PointOfSaleOrderSyncErrorMessageViewModel)

        static func == (lhs: OrderState, rhs: OrderState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                (.syncing, .syncing),
                (.loaded, .loaded),
                (.error, .error):
                return true
            default:
                return false
            }
        }

        var isSyncing: Bool {
            switch self {
            case .syncing:
                return true
            default:
                return false
            }
        }

        var isLoaded: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }

        var isError: Bool {
            switch self {
            case .error:
                return true
            default:
                return false
            }
        }
    }
}
