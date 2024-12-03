import Foundation
import Combine

import protocol Yosemite.POSOrderableItem
import protocol WooFoundation.Analytics
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCartItem

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

    var itemListState: ItemListState { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async

    var cart: [CartItem] { get }
    func addToCart(_ item: POSOrderableItem)
    func remove(cartItem: CartItem)
    func removeAllItemsFromCart()
    func addMoreToCart()
    func startNewCart()

    var orderState: PointOfSaleOrderState { get }
    func checkOut() async
}

class PointOfSaleAggregateModel: ObservableObject, PointOfSaleAggregateModelProtocol {
    @Published private(set) var orderStage: PointOfSaleOrderStage = .building

    @Published private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    @Published private(set) var paymentState: PointOfSalePaymentState
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    private var onOnboardingCancellation: (() -> Void)?

    @Published private(set) var itemListState: ItemListState = .initialLoading

    @Published private(set) var cart: [CartItem] = []

    @Published private(set) var orderState: PointOfSaleOrderState = .idle
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
         paymentState: PointOfSalePaymentState = .idle) {
        self.itemsController = itemsController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.analytics = analytics
        self.paymentState = paymentState
        publishItemListState()
        publishCardReaderConnectionStatus()
        publishPaymentMessages()
        publishOrderState()
        observeInternalOrderState()
        setupReaderReconnectionObservation()
    }
}

// MARK: - ItemList
extension PointOfSaleAggregateModel {
    private func publishItemListState() {
        itemsController.itemListStatePublisher.assign(to: &$itemListState)
    }

    @MainActor
    func loadInitialItems() async {
        await itemsController.loadInitialItems()
    }

    @MainActor
    func loadNextItems() async {
        await itemsController.loadNextItems()
    }

    @MainActor
    func reload() async {
        await itemsController.reload()
    }
}

// MARK: - Cart

extension PointOfSaleAggregateModel {
    func addToCart(_ item: POSOrderableItem) {
        cart.insert(CartItem(id: UUID(), item: item, quantity: 1), at: 0)
        Task { @MainActor in
            analytics.track(.pointOfSaleAddItemToCart)
        }
    }

    func remove(cartItem: CartItem) {
        cart.removeAll(where: { $0.id == cartItem.id } )
    }

    func removeAllItemsFromCart() {
        cart.removeAll()
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
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
    }
}

// MARK: - Card payments

extension PointOfSaleAggregateModel {
    private func publishCardReaderConnectionStatus() {
        // When adopting Observable, we can use `assign(to: on:)` here instead
        cardPresentPaymentService.readerConnectionStatusPublisher.assign(to: &$cardReaderConnectionStatus)
    }

    func connectCardReader() {
        Task { @MainActor in
            _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func disconnectCardReader() {
        Task { @MainActor in
            await cardPresentPaymentService.disconnectReader()
        }
    }

    /// Starts a payment immediately if a reader is connected.
    /// Otherwise, schedules a payment to start the next time a reader connects.
    /// Note that any schedlued payments are cancelled by `cancelReaderPreparation`
    /// e.g. when the TotalsView goes offscreen.
    func startPaymentWhenCardReaderConnected() async {
        guard case .connected = cardReaderConnectionStatus else {
            return startPaymentOnCardReaderConnection = $cardReaderConnectionStatus
                .filter { status in
                    switch status {
                    case .connected:
                        return true
                    case .disconnected, .disconnecting, .cancellingConnection:
                        return false
                    }
                }
                .removeDuplicates()
                .sink { _ in
                    Task { @MainActor [weak self] in
                        await self?.collectPayment()
                    }
                }
        }
        await collectPayment()
    }

    @MainActor
    func collectPayment() async {
        guard let order = orderController.order else {
            return
            // Should this throw?
        }
        do {
            try await collectPayment(for: order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    @MainActor
    func sendReceipt(to emailAddress: String) async {
        // TODO:
        // Add eligiblity for correct WC and WCPay versions
        if case let .loaded(_, order) = internalOrderState {
            await orderController.sendOrderReceipt(order: order, recipientEmail: emailAddress)
        }
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth, channel: .pos)
    }

    func cancelThenCollectPayment() {
        cardPresentPaymentService.cancelPayment()
        Task { [weak self] in
            await self?.collectPayment()
        }
    }

    private func setupReaderReconnectionObservation() {
        $orderStage.sink(receiveValue: { [weak self] stage in
            guard let self else { return }
            switch stage {
            case .building:
                cancelCardReaderPreparation()
            case .finalizing:
                observeReaderReconnection()
            }
        })
        .store(in: &cancellables)
    }

    private func cancelCardReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        startPaymentOnCardReaderConnection?.cancel()
        cardReaderDisconnection?.cancel()
    }

    private func observeReaderReconnection() {
        cardReaderDisconnection = $cardReaderConnectionStatus
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
            .assign(to: &$cardPresentPaymentAlertViewModel)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .assign(to: &$cardPresentPaymentInlineMessage)

        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent in
                guard let self else { return .none }
                return PointOfSalePaymentState(from: paymentEvent,
                                               using: presentationStyleDeterminerDependencies)
            }
            .assign(to: &$paymentState)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentsOnboardingViewModel? in
                guard let self else { return nil }
                guard case let .showOnboarding(viewModel, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return viewModel
            }
            .assign(to: &$cardPresentPaymentOnboardingViewModel)
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
            .assign(to: &$orderState)
    }

    private func observeInternalOrderState() {
        orderController.orderStatePublisher
            .sink { [weak self] state in
                self?.internalOrderState = state
            }
            .store(in: &cancellables)
    }
}

private extension PointOfSaleAggregateModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}
