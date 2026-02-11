import CocoaLumberjackSwift
import Foundation
import Combine

import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState
import protocol Yosemite.PaymentCaptureCelebrationProtocol

/// Shared payment model that owns all payment state and logic.
@Observable
final class POSPaymentModel {
    // MARK: - State (read by views)
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    private(set) var cardReaderUpdateState: CardReaderSoftwareUpdateState = .none
    var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer?
    var isZeroTotal: Bool {
        guard let total = currentOrder?.total, let decimal = Decimal(string: total) else { return false }
        return decimal == 0
    }

    var isCardReaderUpdateAvailable: Bool {
        if case .available = cardReaderUpdateState {
            return true
        }
        return false
    }

    // MARK: - Dependencies
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderProvider: POSPaymentOrderProviding
    private let cashPaymentHandler: POSCashPaymentHandling
    private let receiptSender: POSReceiptSending
    private let postPaymentStep: (() async throws -> Void)?
    let configuration: POSPaymentFlowConfiguration
    private let analytics: POSAnalyticsProviding
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let celebration: PaymentCaptureCelebrationProtocol

    // MARK: - Internal
    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?
    private var onOnboardingCancellation: (() -> Void)?
    private var cancellables: Set<AnyCancellable> = []
    private var paymentSessionCancellables: Set<AnyCancellable> = []
    private var currentOrder: Order?
    private var formattedOrderTotalPrice: String?

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         orderProvider: POSPaymentOrderProviding,
         cashPaymentHandler: POSCashPaymentHandling,
         receiptSender: POSReceiptSending,
         postPaymentStep: (() async throws -> Void)? = nil,
         configuration: POSPaymentFlowConfiguration,
         analytics: POSAnalyticsProviding,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         celebration: PaymentCaptureCelebrationProtocol,
         paymentState: PointOfSalePaymentState = .idle) {
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderProvider = orderProvider
        self.cashPaymentHandler = cashPaymentHandler
        self.receiptSender = receiptSender
        self.postPaymentStep = postPaymentStep
        self.configuration = configuration
        self.analytics = analytics
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.celebration = celebration
        self.paymentState = paymentState

        publishCardReaderConnectionStatus()
        publishCardReaderUpdateState()
        subscribeToAlwaysOnPaymentEvents()
    }
}

// MARK: - Card Payment Methods
extension POSPaymentModel {
    /// Cancels any existing payment on the shared reader, then starts a new payment.
    /// Collects immediately if a reader is connected; otherwise waits for connection.
    func startPayment() async {
        subscribeToPaymentSessionEvents()
        try? await cardPresentPaymentService.cancelPayment()
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

    private func collectCardPayment() async {
        do {
            let paymentOrder = try await orderProvider.provideOrder()
            currentOrder = paymentOrder.order
            formattedOrderTotalPrice = paymentOrder.formattedTotal
            guard paymentOrder.totalDecimal > 0 else { return }
            try await collectPayment(for: paymentOrder.order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

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

    func connectCardReader() {
        analytics.track(.pointOfSaleCardReaderConnectionTapped)
        Task { @MainActor [weak self] in
            _ = try await self?.cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func disconnectCardReader() {
        analytics.track(.cardReaderDisconnectTapped)
        Task { @MainActor [weak self] in
            await self?.cardPresentPaymentService.disconnectReader()
        }
    }

    func updateCardReaderSoftware() {
        Task { @MainActor [weak self] in
            try? await self?.cardPresentPaymentService.updateCardReaderSoftware()
        }
    }

    func cancelCardPaymentsOnboarding() {
        guard let onboardingViewContainer = cardPresentPaymentOnboardingViewContainer else {
            return
        }
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewContainer.configuration.state))
        cardPresentPaymentOnboardingViewContainer = nil
        onOnboardingCancellation?()
    }

    func trackCardPaymentsOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }
}

// MARK: - Cash Payment Methods
extension POSPaymentModel {
    func startCashPayment() async {
        analytics.track(.pointOfSaleCheckoutCashPaymentTapped)
        try? await cardPresentPaymentService.cancelPayment()
        paymentState.cash = .collectingCash
    }

    func cancelCashPayment() async {
        analytics.track(.pointOfSaleBackToCheckoutFromCashTapped)
        paymentState.cash = .idle
        if case .connected = cardReaderConnectionStatus {
            await collectCardPayment()
        }
    }

    func collectCashPayment(changeDueAmount: String?) async throws {
        let order: Order
        if let currentOrder {
            order = currentOrder
        } else {
            let paymentOrder = try await orderProvider.provideOrder()
            order = paymentOrder.order
            currentOrder = order
        }
        try await cashPaymentHandler.completeCashPayment(for: order, changeDueAmount: changeDueAmount)
        try? await postPaymentStep?()
        cashPaymentSuccess()
    }

    private func cashPaymentSuccess() {
        paymentState.cash = .paymentSuccess
        collectOrderPaymentAnalyticsTracker.trackSuccessfulCashPayment()
        celebration.celebrate()
    }
}

// MARK: - Receipt
extension POSPaymentModel {
    func sendReceipt(to emailAddress: String) async throws {
        guard let order = currentOrder else {
            throw POSPaymentError.noOrder
        }
        try await receiptSender.sendReceipt(orderID: order.orderID, recipientEmail: emailAddress)
    }
}

// MARK: - Session Management
extension POSPaymentModel {
    /// Whether this payment model is currently active (session subscriptions are listening).
    var isActive: Bool {
        !paymentSessionCancellables.isEmpty
    }

    /// Deactivates this payment model when another flow takes the foreground.
    /// Cancels any in-progress card payment, removes subscriptions, but preserves
    /// payment state and order data so `activate()` can resume where we left off.
    func deactivate() {
        paymentSessionCancellables.removeAll()
        cancelReaderPreparation()
    }

    /// Reactivates this payment model when it returns to the foreground.
    /// For card payments, restarts the full payment flow (cancel + collect).
    /// For cash payments, restores session event subscriptions without activating the reader.
    func activate() async {
        guard !isActive else { return }
        if paymentState.activePaymentMethod == .card {
            await startPayment()
        } else {
            subscribeToPaymentSessionEvents()
        }
    }
}

// MARK: - Reset
extension POSPaymentModel {
    func reset() {
        paymentSessionCancellables.removeAll()
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
        currentOrder = nil
        formattedOrderTotalPrice = nil
        cancelReaderPreparation()
    }

    private func cancelReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        resetCardReaderObservation()
    }

    private func resetCardReaderObservation() {
        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        cardReaderDisconnection?.cancel()
        cardReaderDisconnection = nil
    }
}

// MARK: - Reader Reconnection
extension POSPaymentModel {
    func observeReaderReconnection() {
        cardReaderDisconnection = cardPresentPaymentService.readerConnectionStatusPublisher
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPayment()
                }
            }
    }

    func cancelReaderReconnectionObservation() {
        cancelReaderPreparation()
    }
}

// MARK: - Combine Subscriptions
private extension POSPaymentModel {
    func publishCardReaderConnectionStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .sink(receiveValue: { [weak self] connectionStatus in
                self?.cardReaderConnectionStatus = connectionStatus
            })
            .store(in: &cancellables)
    }

    func publishCardReaderUpdateState() {
        cardPresentPaymentService.cardReaderUpdateStatePublisher
            .sink(receiveValue: { [weak self] updateState in
                self?.cardReaderUpdateState = updateState
            })
            .store(in: &cancellables)
    }

    /// Always-on subscriptions for reader connection alerts and onboarding.
    /// These are needed regardless of whether a payment session is active.
    func subscribeToAlwaysOnPaymentEvents() {
        // Payment events -> alert view model (modal alerts for reader connection)
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentAlertType? in
                guard let self else { return nil }
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = presentationStyle(for: eventDetails)
                else {
                    return nil
                }

                // Filter connection success alerts when we're immediately starting a payment
                if case .connectionSuccess = eventDetails,
                   startPaymentOnCardReaderConnection != nil {
                    return nil
                }

                return alertType
            }
            .sink(receiveValue: { [weak self] alertType in
                self?.cardPresentPaymentAlertViewModel = alertType
            })
            .store(in: &cancellables)

        // Payment events -> onboarding view (card reader setup)
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentOnboardingViewContainer? in
                guard let self else { return nil }
                guard case let .showOnboarding(factory, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return factory
            }
            .sink(receiveValue: { [weak self] factory in
                self?.cardPresentPaymentOnboardingViewContainer = factory
            })
            .store(in: &cancellables)
    }

    /// Session-scoped subscriptions for payment state and inline messages.
    /// Only active during a payment session (between startPayment() and reset()/tearDown()).
    /// This prevents payment events from one flow (e.g. bookings) corrupting another (e.g. cart).
    func subscribeToPaymentSessionEvents() {
        guard paymentSessionCancellables.isEmpty else { return }

        // Payment events -> inline message (payment status in the totals view)
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .sink(receiveValue: { [weak self] message in
                self?.cardPresentPaymentInlineMessage = message
            })
            .store(in: &paymentSessionCancellables)

        // Payment events -> card payment state
        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent -> PointOfSaleCardPaymentState? in
                guard let self else { return nil }

                let newCardPaymentState = PointOfSaleCardPaymentState(from: paymentEvent,
                                                                      using: presentationStyleDeterminerDependencies)

                if case .acceptingCard = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderReady()
                }

                if case .processingPayment = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderTapped()
                }

                return newCardPaymentState
            }
            .sink(receiveValue: { [weak self] cardPaymentState in
                self?.paymentState.card = cardPaymentState
            })
            .store(in: &paymentSessionCancellables)
    }

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
        let cancelThenCollectPaymentAction: () -> Void = { [weak self] in
            self?.cancelThenCollectPayment()
        }

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentAction,
            nonRetryableErrorExitAction: cancelThenCollectPaymentAction,
            formattedOrderTotalPrice: formattedOrderTotalPrice,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentAction,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.configuration.captureErrorExitAction.action()
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.configuration.intentCreationErrorExitAction.action()
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
    }
}

// MARK: - Cleanup
extension POSPaymentModel {
    /// Cancels any in-progress payment and cleans up subscriptions.
    /// We cancel payments to prevent the reader from remaining live and awaiting a card tap.
    /// Otherwise, it would wait until the timeout (30-45 minutes), using more battery
    /// and risking a shopper paying for the wrong order.
    func tearDown() {
        cardPresentPaymentService.cancelPayment()
        resetCardReaderObservation()
        paymentSessionCancellables.removeAll()
        cancellables.forEach { $0.cancel() }
    }
}

#if DEBUG
extension POSPaymentModel {
    func setPreviewState(paymentState: PointOfSalePaymentState, inlineMessage: PointOfSaleCardPresentPaymentMessageType?) {
        self.paymentState = paymentState
        self.cardPresentPaymentInlineMessage = inlineMessage
    }
}
#endif
