import Foundation
import Combine
import Observation

import protocol Yosemite.POSOrderableItem
import protocol WooFoundation.Analytics
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCartItem
import enum Yosemite.POSItem
import enum Yosemite.SystemStatusAction

@available(iOS 17.0, *)
protocol PointOfSaleAggregateModelProtocol {
    var orderStage: PointOfSaleOrderStage { get }

    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus { get }
    func connectCardReader()
    func disconnectCardReader()
    var paymentState: PointOfSalePaymentState { get }
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? { get set }
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel? { get set }
    func cancelCardPaymentsOnboarding()
    func trackCardPaymentsOnboardingShown()

    var itemsViewState: ItemsViewState { get }
    func loadItems(base: ItemListBaseItem) async
    func loadNextItems(base: ItemListBaseItem) async

    var cart: [CartItem] { get }
    func addToCart(_ item: POSItem)
    func remove(cartItem: CartItem)
    func removeAllItemsFromCart()
    func addMoreToCart()
    func startNewCart()

    var orderState: PointOfSaleOrderState { get }
    func checkOut() async
}

@available(iOS 17.0, *)
@Observable final class PointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    private(set) var orderStage: PointOfSaleOrderStage = .building

    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    private var onOnboardingCancellation: (() -> Void)?

    var itemsViewState: ItemsViewState { itemsController.itemsViewState }

    private(set) var cart: [CartItem] = []

    private(set) var orderState: PointOfSaleOrderState = .idle
    private var internalOrderState: PointOfSaleInternalOrderState = .idle

    private let itemsController: PointOfSaleItemsControllerProtocol

    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let analytics: Analytics

    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    private var cancellables: Set<AnyCancellable> = []

    init(itemsController: PointOfSaleItemsControllerProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         analytics: Analytics = ServiceLocator.analytics,
         paymentState: PointOfSalePaymentState = .card(.idle)) {
        self.itemsController = itemsController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.analytics = analytics
        self.paymentState = paymentState
        publishCardReaderConnectionStatus()
        publishPaymentMessages()
        publishOrderState()
        setupReaderReconnectionObservation()
    }
}

// MARK: - ItemList
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    @MainActor
    func loadItems(base: ItemListBaseItem) async {
        await itemsController.loadItems(base: base)
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        await itemsController.loadNextItems(base: base)
    }
}

// MARK: - Cart

private extension POSItem {
    var cartItem: CartItem? {
        switch self {
        case .simpleProduct(let simpleProduct):
            return CartItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
        case .variation(let variation):
            return CartItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
        case .variableParentProduct:
            return nil
        }
    }
}

@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    func addToCart(_ item: POSItem) {
        guard let cartItem = item.cartItem else { return }
        cart.insert(cartItem, at: cart.startIndex)
    }

    func remove(cartItem: CartItem) {
        cart.removeAll(where: { $0.id == cartItem.id } )
    }

    func removeAllItemsFromCart() {
        cart.removeAll()
        analytics.track(.pointOfSaleClearCartTapped)
    }

    func addMoreToCart() {
        setStateForEditing()
    }

    func startNewCart() {
        removeAllItemsFromCart()
        orderController.clearOrder()
        setStateForEditing()
    }

    private func setStateForEditing() {
        orderStage = .building
        paymentState = .card(.idle)
        cardPresentPaymentInlineMessage = nil
    }
}

// MARK: - Card payments
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    private func publishCardReaderConnectionStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .sink(receiveValue: { [weak self] connectionStatus in
                self?.cardReaderConnectionStatus = connectionStatus
            })
            .store(in: &cancellables)
    }

    func connectCardReader() {
        analytics.track(.pointOfSaleCardReaderConnectionTapped)
        Task { @MainActor in
            _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func disconnectCardReader() {
        analytics.track(.cardReaderDisconnectTapped)
        Task { @MainActor in
            await cardPresentPaymentService.disconnectReader()
        }
    }

    /// Starts a payment immediately if a reader is connected.
    /// Otherwise, schedules a payment to start the next time a reader connects.
    /// Note that any scheduled payments are cancelled by `cancelReaderPreparation`
    /// e.g. when the TotalsView goes offscreen.
    private func startPaymentWhenCardReaderConnected() async {
        guard case .connected = cardReaderConnectionStatus else {
            return startPaymentOnCardReaderConnection = cardPresentPaymentService.readerConnectionStatusPublisher
                .filter { status in
                    switch status {
                    case .connected:
                        return true
                    case .disconnected, .disconnecting, .cancellingConnection:
                        return false
                    }
                }
                .removeDuplicates()
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.collectCardPayment()
                    }
                }
        }
        await collectCardPayment()
    }

    @MainActor
    private func collectCardPayment() async {
        guard case let .loaded(totals, order) = internalOrderState,
              totals.orderTotalDecimal > 0.0
        else {
            return
            // Should this throw?
        }
        do {
            try await collectPayment(for: order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    // Prevents card payments from the moment the merchant decides we start collecting cash
    // Once we get the callback from the card service, we switch to cash collection state
    @MainActor
    func startCashPayment() async {
        try? await cardPresentPaymentService.cancelPayment()
        paymentState = .cash(.collectingCash)
    }

    @MainActor
    func cancelCashPayment() async {
        paymentState = .card(.idle)
        if case .connected = cardReaderConnectionStatus {
            await collectCardPayment()
        }
    }

    private func cashPaymentSuccess() {
        paymentState = .cash(.paymentSuccess)
    }

    @MainActor
    func collectCashPayment() async throws {
        try await orderController.collectCashPayment()
        cashPaymentSuccess()
    }

    @MainActor
    func sendReceipt(to emailAddress: String) async throws {
        try await orderController.sendReceipt(recipientEmail: emailAddress)
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth, channel: .pos)
    }

    func cancelThenCollectPayment() {
        Task { [weak self] in
            guard let self else { return }
            await cancelThenCollectPayment()
        }
    }

    func cancelThenCollectPayment() async {
        try? await cardPresentPaymentService.cancelPayment()
        await collectCardPayment()
    }

    @Sendable private func setupReaderReconnectionObservation() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            switch orderStage {
                case .building:
                    cancelCardReaderPreparation()
                case .finalizing:
                    observeReaderReconnection()
            }
        } onChange: { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async(execute: setupReaderReconnectionObservation)
        }
    }

    private func cancelCardReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        startPaymentOnCardReaderConnection?.cancel()
        cardReaderDisconnection?.cancel()
    }

    private func observeReaderReconnection() {
        cardReaderDisconnection = cardPresentPaymentService.readerConnectionStatusPublisher
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPaymentWhenCardReaderConnected()
                }
            }
    }

    /// Called when the onboarding UI is dismissed.
    /// For external dismissal (tapping CTA to dismiss), this method is called twice - the first time to dismiss the onboarding UI
    /// by setting `cardPresentPaymentOnboardingViewModel` to nil, the second time triggered by internal dismissal.
    /// For internal dismissal (tapping outside the modal), this method is called once.
    /// This method is used to reset the internal state of the onboarding UI and track the dismissal event.
    func cancelCardPaymentsOnboarding() {
        guard let onboardingViewModel = cardPresentPaymentOnboardingViewModel else {
            return
        }
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewModel.state))
        cardPresentPaymentOnboardingViewModel = nil
        onOnboardingCancellation?()
    }

    /// Tracks when the onboarding UI is shown.
    func trackCardPaymentsOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleAggregateModel {
    func publishPaymentMessages() {
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
            .sink(receiveValue: { [weak self] alertType in
                self?.cardPresentPaymentAlertViewModel = alertType
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .sink(receiveValue: { [weak self] message in
                self?.cardPresentPaymentInlineMessage = message
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent -> PointOfSalePaymentState? in
                guard let self else { return nil }

                let newPaymentState = PointOfSalePaymentState(from: paymentEvent,
                                                              using: presentationStyleDeterminerDependencies)

                return newPaymentState
            }
            .sink(receiveValue: { [weak self] paymentState in
                self?.paymentState = paymentState
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentsOnboardingViewModel? in
                guard let self else { return nil }
                guard case let .showOnboarding(viewModel, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return viewModel
            }
            .sink(receiveValue: { [weak self] onboardingViewModel in
                self?.cardPresentPaymentOnboardingViewModel = onboardingViewModel
            })
            .store(in: &cancellables)
    }

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

        var orderTotal: String?
        if case .loaded(let totals) = orderState {
            orderTotal = totals.orderTotal
        }

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentWithWeakSelf,
            nonRetryableErrorExitAction: cancelThenCollectPaymentWithWeakSelf,
            formattedOrderTotalPrice: orderTotal,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentWithWeakSelf,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.startNewCart()
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.addMoreToCart()
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
    }
}

// MARK: - Order syncing
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    @MainActor
    func checkOut() async {
        orderStage = .finalizing
        await orderController.syncOrder(for: cart, retryHandler: { [weak self] in
            await self?.checkOut()
        })
        await startPaymentWhenCardReaderConnected()
    }

    func publishOrderState() {
        orderController.orderStatePublisher
            .map { $0.externalState }
            .sink(receiveValue: { [weak self] orderState in
                self?.orderState = orderState
            })
            .store(in: &cancellables)

        orderController.orderStatePublisher
            .sink(receiveValue: { [weak self] internalOrderState in
                self?.internalOrderState = internalOrderState
            })
            .store(in: &cancellables)
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleAggregateModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}
