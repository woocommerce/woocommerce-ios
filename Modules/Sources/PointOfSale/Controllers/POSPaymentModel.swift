import CocoaLumberjackSwift
import Foundation
import Combine

import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState
import protocol Yosemite.PaymentCaptureCelebrationProtocol
import class Yosemite.PaymentCaptureCelebration

/// Shared payment model that owns all payment state and logic.
@MainActor
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

    var customerBillingEmail: String? {
        currentOrder?.billingAddress?.email
    }

    var isCardReaderUpdateAvailable: Bool {
        if case .available = cardReaderUpdateState {
            return true
        }
        return false
    }

    /// True while the silent Tap to Pay pre-connect is still in flight: the
    /// merchant is on the TTP path and the reader hasn't moved out of
    /// `.disconnected` yet. Drives the hero's "Preparing Tap to Pay…"
    /// affordance so the merchant gets feedback during the (usually short)
    /// pre-connect window.
    var isPreparingTapToPay: Bool {
        guard preferredConnectionMethod == .tapToPay else { return false }
        // If a non-TTP session is in flight (BT picked via the sheet),
        // we deliberately disconnected TTP — showing "Preparing Tap to Pay…"
        // would mislead. The BT path drives its own UI from here.
        if let currentPaymentMethod, currentPaymentMethod != .tapToPay { return false }
        if case .disconnected = cardReaderConnectionStatus { return true }
        return false
    }

    /// The connection method of the currently active payment session, or nil
    /// between sessions. Distinct from `preferredConnectionMethod` (the POS
    /// session's default): the merchant can pick BT via the "Other payment
    /// methods" sheet on a TTP-default device, in which case the active
    /// session is `.bluetooth` even though preferred remains `.tapToPay`.
    /// This is the field that gates the intermediate-state filter and the
    /// model-side re-entry guard.
    private(set) var currentPaymentMethod: CardReaderConnectionMethod?

    /// True while *any* collection session is active (TTP or BT). Drives
    /// TotalsView's `isStartingPayment` reset — when this transitions back
    /// to false the merchant's flow has wrapped up (success, error, cancel,
    /// BT scan dismissed, etc.) and the hero CTA + bottom strip can become
    /// tappable again.
    var isPaymentSessionActive: Bool {
        currentPaymentMethod != nil
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

    /// The reader connection method this POS session should use as its default.
    ///
    /// `.bluetooth` (iPad / phone without TTP eligibility) keeps the classic
    /// auto-collect-on-connect behaviour: when the merchant enters checkout
    /// `startPayment()` waits for any BT reader to come up and collects via that.
    /// `.tapToPay` (phone with TTP eligibility) only pre-connects the built-in
    /// reader on checkout — collection is gated behind an explicit method tap
    /// from the buttons row / hero via `startPaymentWithMethod(_:)`, so the
    /// merchant's selection drives which method actually runs.
    let preferredConnectionMethod: CardReaderConnectionMethod

    // MARK: - Internal
    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?
    /// Incremented each time `startPayment()` is called so that stale
    /// `startPaymentOnCardReaderConnection` callbacks (which may already
    /// have been enqueued as Tasks) can detect they've been superseded.
    private var startPaymentGeneration: Int = 0
    private var cardPaymentCancelTask: Task<Void, Never>?
    private var connectCardReaderTask: Task<Void, Never>?

    /// On the TTP path, payment state should only advance when the merchant has
    /// explicitly tapped a method (hero CTA or Other payment methods sheet row).
    /// Otherwise stale Stripe Terminal events that arrive during Apple's modal
    /// teardown / cancel sequence flip `paymentState.card` back to states like
    /// `.acceptingCard` for a frame and yank the hero away. This gate, set true
    /// at init and after a TTP cancel, blocks event-driven updates until the
    /// next `startPaymentWithMethod`. Always false on the Bluetooth path so
    /// auto-collect-on-connect keeps working as today.
    private var isAwaitingExplicitPaymentStart: Bool = true
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
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration(),
         preferredConnectionMethod: CardReaderConnectionMethod = .bluetooth,
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
        self.preferredConnectionMethod = preferredConnectionMethod
        self.paymentState = paymentState

        publishCardReaderConnectionStatus()
        publishCardReaderUpdateState()
        subscribeToAlwaysOnPaymentEvents()
    }
}

// MARK: - Card Payment Methods
extension POSPaymentModel {
    /// Called by the aggregate model when checkout opens.
    ///
    /// Bluetooth path: runs the auto-collect-on-connect flow that's been there forever
    /// — wait for any reader to come up, then collect via that.
    ///
    /// Tap to Pay path: only pre-connects the built-in reader. Collection is gated
    /// behind an explicit `startPaymentWithMethod(.tapToPay)` from the hero CTA so
    /// the merchant's selection drives the actual flow — no auto-collect to race.
    func startPayment() async {
        DDLogInfo("🃏 [CardPayment] startPayment called — card state: \(paymentState.card), cash state: \(paymentState.cash)")

        subscribeToPaymentSessionEvents()

        if preferredConnectionMethod == .tapToPay {
            // Awaiting an explicit method tap from the hero / sheet — leave the
            // gate true so transient Stripe events during pre-connect can't
            // advance the state machine. No `currentPaymentMethod` yet — the
            // session hasn't actually started.
            connectTapToPayReader()
            return
        }

        // BT auto-collect path — events from the connected reader are the
        // intended source of state transitions.
        currentPaymentMethod = preferredConnectionMethod
        isAwaitingExplicitPaymentStart = false
        await startPaymentFlow(using: preferredConnectionMethod)
    }

    /// Starts payment with an explicit connection method, used when the merchant
    /// picks Tap to Pay or Card reader from the totals checkout buttons / sheet.
    ///
    /// Switches readers if needed (TTP connected and the merchant picks Bluetooth
    /// triggers a disconnect first), kicks off a connect with the chosen method if
    /// disconnected, then runs the same auto-collect-on-connect flow Bluetooth uses
    /// — but threaded through with the explicit method so the eventual collect
    /// targets the reader that's actually coming up.
    func startPaymentWithMethod(_ method: CardReaderConnectionMethod) async {
        DDLogInfo("🃏 [CardPayment] startPaymentWithMethod \(method) — status: \(cardReaderConnectionStatus)")

        // Defensive re-entry guard: only kick a fresh flow off the idle state.
        // If a payment is already mid-flight (preparing, accepting, processing,
        // success, error), a second call from a stray closure / restored
        // subscription / SwiftUI re-render could clobber generation tracking
        // and confuse the Stripe Terminal state machine. The hero / sheet
        // buttons in `TotalsView` already double-tap-protect via the
        // `isStartingPayment` gate; this is the model-side belt to that.
        guard paymentState.card == .idle else {
            DDLogInfo("🃏 [CardPayment] startPaymentWithMethod ignored — card state is \(paymentState.card)")
            return
        }
        // On TTP we suppress the intermediate card states so `paymentState.card`
        // stays `.idle` for the entire collection session — the guard above
        // therefore can't catch re-entry there. `currentPaymentMethod` is the
        // canonical "in flight" check for TTP.
        if currentPaymentMethod == .tapToPay {
            DDLogInfo("🃏 [CardPayment] startPaymentWithMethod ignored — TTP session already active")
            return
        }

        if method == .tapToPay {
            analytics.track(.pointOfSaleCheckoutTapToPayTapped)
        }

        subscribeToPaymentSessionEvents()
        // Merchant explicitly chose a method — track it as the active session
        // method (drives the intermediate-state filter) and open the gate so
        // subsequent Stripe Terminal events drive the state machine.
        currentPaymentMethod = method
        isAwaitingExplicitPaymentStart = false

        // If a reader is connected via the *other* method, drop it before
        // connecting via the chosen one. Stripe Terminal can only have one
        // active reader; without the disconnect the new connect would be
        // rejected. iPad never hits this branch (preferred is always
        // bluetooth there), so the disconnect is scoped to the phone-with-TTP
        // method-switch case.
        if case .connected = cardReaderConnectionStatus {
            if method == .bluetooth, preferredConnectionMethod == .tapToPay {
                await cardPresentPaymentService.disconnectReader()
            } else if method == .tapToPay, preferredConnectionMethod == .bluetooth {
                await cardPresentPaymentService.disconnectReader()
            }
        }

        if case .disconnected = cardReaderConnectionStatus {
            Task { @MainActor [weak self] in
                _ = try? await self?.cardPresentPaymentService.connectReader(using: method)
            }
        }

        await startPaymentFlow(using: method)
    }

    /// Pre-connects the built-in Tap to Pay reader without starting collection.
    /// Called from `startPayment()` when `preferredConnectionMethod == .tapToPay`,
    /// so the reader is warm by the time the merchant taps the hero CTA.
    func connectTapToPayReader() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Stripe Terminal can only hold one active reader. If an old reader
            // is still attached when we enter POS (a stale TTP / BT session
            // carried across app launches, or a BT reader from a previous
            // mode), connecting on top would fail with "another reader is
            // already connected" and surface a disruptive failure modal —
            // for a connect the merchant didn't even ask for. Drop it first.
            if case .connected = cardReaderConnectionStatus {
                await cardPresentPaymentService.disconnectReader()
            }
            _ = try? await cardPresentPaymentService.connectReader(using: .tapToPay)
        }
    }

    /// Runs the auto-collect-on-connect flow for the given method.
    /// Cancels any existing payment, then collects immediately if a reader is
    /// already connected — otherwise sets up a one-shot subscription that fires
    /// when one connects.
    private func startPaymentFlow(using method: CardReaderConnectionMethod) async {
        // Invalidate stale `startPaymentOnCardReaderConnection` callbacks
        // so only the latest subscription can reach `collectCardPayment`.
        startPaymentGeneration += 1
        let generation = startPaymentGeneration

        // Check reader status synchronously — before any `await` — so
        // concurrent calls on @MainActor all see the same state and
        // can't race into different branches.
        guard case .connected = cardReaderConnectionStatus else {
            DDLogInfo("🃏 [CardPayment] reader not connected, waiting for connection")
            startPaymentOnCardReaderConnection?.cancel()
            startPaymentOnCardReaderConnection = cardPresentPaymentService.readerConnectionStatusPublisher
                .filter { status in
                    switch status {
                    case .connected:
                        return true
                    case .disconnected, .disconnecting, .cancellingConnection, .reconnecting:
                        return false
                    }
                }
                .removeDuplicates()
                .sink { [weak self, generation, method] _ in
                    Task { @MainActor [weak self] in
                        guard self?.startPaymentGeneration == generation else { return }
                        await self?.cancelThenCollectCardPayment(generation: generation, using: method)
                    }
                }
            return
        }

        // Reader is connected — cancel any stale payment, then collect.
        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        await cancelThenCollectCardPayment(generation: generation, using: method)
    }

    /// Cancels any stale payment on the reader, then collects via the given method.
    /// The generation check after the cancel guards against a newer
    /// `startPayment()` call that may have started during the await.
    private func cancelThenCollectCardPayment(generation: Int, using method: CardReaderConnectionMethod) async {
        try? await cardPresentPaymentService.cancelPayment()
        DDLogInfo("🃏 [CardPayment] startPayment cancel completed — card state: \(paymentState.card), cash state: \(paymentState.cash)")

        guard startPaymentGeneration == generation else {
            DDLogInfo("🃏 [CardPayment] startPayment superseded by a newer call, bailing out")
            return
        }

        DDLogInfo("🃏 [CardPayment] startPayment proceeding to collectCardPayment")
        await collectCardPayment(using: method)
    }

    private func collectCardPayment(using method: CardReaderConnectionMethod) async {
        DDLogInfo("🃏 [CardPayment] collectCardPayment(\(method)) called — card state: \(paymentState.card), cash state: \(paymentState.cash)")
        do {
            let paymentOrder = try await orderProvider.provideOrder()
            currentOrder = paymentOrder.order
            formattedOrderTotalPrice = paymentOrder.formattedTotal
            guard paymentOrder.totalDecimal > 0 else { return }
            try await collectPayment(for: paymentOrder.order, using: method)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    private func collectPayment(for order: Order, using method: CardReaderConnectionMethod) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: method, channel: .pos)
    }

    func cancelThenCollectPayment() {
        Task { [weak self] in
            guard let self else { return }
            await cancelThenCollectPayment()
        }
    }

    func cancelThenCollectPayment() async {
        if case .reconnecting = cardReaderConnectionStatus {
            await cardPresentPaymentService.cancelReconnection()
        }

        try? await cardPresentPaymentService.cancelPayment()

        guard case .connected = cardReaderConnectionStatus else {
            return
        }
        await collectCardPayment(using: preferredConnectionMethod)
    }

    func connectCardReader() {
        analytics.track(.pointOfSaleCardReaderConnectionTapped)
        guard connectCardReaderTask == nil else { return }
        connectCardReaderTask = Task { @MainActor [weak self] in
            defer { self?.connectCardReaderTask = nil }
            _ = try? await self?.cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func cancelReconnection() {
        Task { @MainActor [weak self] in
            await self?.cardPresentPaymentService.cancelReconnection()
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
    func startCashPayment() {
        guard paymentState.cash == .idle else { return }
        guard paymentState.allowsCashPayment else { return }

        DDLogInfo("💵 [CashPayment] startCashPayment called - card state: \(paymentState.card), cash state: \(paymentState.cash)")
        analytics.track(.pointOfSaleCheckoutCashPaymentTapped)

        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        startPaymentGeneration += 1

        paymentState.cash = .collectingCash

        cardPaymentCancelTask = Task { [weak self] in
            do {
                try await self?.cardPresentPaymentService.cancelPayment()
            } catch {
                DDLogWarn("💵 [CashPayment] failed to cancel card payment: \(error)")
            }
        }
    }

    func cancelCashPayment() async {
        analytics.track(.pointOfSaleBackToCheckoutFromCashTapped)
        paymentState.cash = .idle
        paymentState.card = .idle
        cardPresentPaymentInlineMessage = nil

        await cardPaymentCancelTask?.value
        cardPaymentCancelTask = nil

        await startPayment()
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
        currentOrder = order.copy(billingAddress: order.billingAddress?.copy(email: emailAddress))
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
        DDLogInfo("⏸️ [Session] deactivate called - card state: \(paymentState.card), cash state: \(paymentState.cash)")
        paymentSessionCancellables.removeAll()
        cancelReaderPreparation()
    }

    /// Reactivates this payment model when it returns to the foreground.
    /// For card payments, restarts the full payment flow (cancel + collect).
    /// For cash payments, restores session event subscriptions without activating the reader.
    func activate() async {
        DDLogInfo("▶️ [Session] activate called — isActive: \(isActive), " +
                  "activeMethod: \(paymentState.activePaymentMethod), card: \(paymentState.card), cash: \(paymentState.cash)")
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
        cancelConnectCardReaderTask()
        paymentSessionCancellables.removeAll()
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
        currentOrder = nil
        formattedOrderTotalPrice = nil
        // Re-arm the TTP gate so re-entering checkout starts clean — `startPayment`
        // will keep it true on the TTP path until the merchant taps a method again.
        isAwaitingExplicitPaymentStart = true
        currentPaymentMethod = nil
        cancelReaderPreparation()
    }

    private func cancelConnectCardReaderTask() {
        connectCardReaderTask?.cancel()
        connectCardReaderTask = nil
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
                    guard let self else { return }
                    // The auto-reconnect is for "reader fell off the device"
                    // scenarios when no payment is in flight. If a session is
                    // active (e.g. a BT-via-sheet pick on a TTP-default
                    // device deliberately disconnected TTP first), the
                    // session manages its own reconnect and we should stay
                    // out of the way — otherwise we race the session's
                    // chosen method and confuse the SDK.
                    guard self.currentPaymentMethod == nil else { return }
                    await self.startPayment()
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
                guard let self else { return }
                cardReaderConnectionStatus = connectionStatus
                if connectionStatus == .disconnected {
                    resetTransientCardStateOnDisconnect()
                }
            })
            .store(in: &cancellables)
    }

    func resetTransientCardStateOnDisconnect() {
        guard paymentState.card.resetsToIdleOnDisconnect else { return }
        DDLogInfo("🔌 [Disconnect] resetting transient card state \(paymentState.card) to idle")
        paymentState.card = .idle
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

                // On the TTP path the merchant never explicitly initiates a reader
                // connection — pre-connect on checkout entry and the connect inside
                // `startPaymentWithMethod` are both transparent. Suppress the
                // discovery / connection lifecycle (scanning, found reader,
                // connecting, connected) when there's no active BT session, so
                // those modals don't pop up for connections the merchant didn't
                // request. When a BT-via-sheet session is active we leave the
                // discovery / connection alerts visible so the merchant can pick
                // a reader and see connection progress. Failures the merchant
                // must actually act on — TTP entitlement / Apple ToS /
                // location-services / postal-code / address — still surface so
                // the merchant can resolve them.
                // The merchant can also kick off a BT scan explicitly via
                // Settings → Hardware → Card readers → Connect card reader,
                // which goes through `connectCardReader()` and sets
                // `connectCardReaderTask`. While that task is in flight the
                // merchant *wants* to see the scan / foundReader / connect
                // / failure modals, so neither suppression block below
                // applies — Settings drives its UI off them.
                let isExplicitConnectInProgress = connectCardReaderTask != nil

                let isInTransparentTapToPayFlow = !isExplicitConnectInProgress
                    && (currentPaymentMethod == .tapToPay
                        || (currentPaymentMethod == nil && preferredConnectionMethod == .tapToPay))
                if isInTransparentTapToPayFlow {
                    switch eventDetails {
                    case .scanningForReaders,
                            .foundReader,
                            .connectingToReader,
                            .connectionSuccess:
                        return nil
                    default:
                        break
                    }
                }

                // Generic "couldn't connect" / "scan failed" / "couldn't connect
                // (non-retryable)" failures aren't actionable for the merchant
                // on a TTP-default device when the connect was implicit (TTP
                // pre-connect, BT-via-sheet cancel residual, etc.). When the
                // merchant explicitly tapped Connect in Settings, they need to
                // see the failure to know to retry or fix something — keep
                // those alerts visible. BT-default devices keep them too.
                if preferredConnectionMethod == .tapToPay && !isExplicitConnectInProgress {
                    switch eventDetails {
                    case .connectingFailed,
                            .connectingFailedNonRetryable,
                            .scanningFailed:
                        return nil
                    default:
                        break
                    }
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
                guard let self else { return nil }
                guard self.shouldPropagatePaymentEvent else { return nil }
                return self.mapCardPresentPaymentEventToMessageType(event)
            }
            .sink(receiveValue: { [weak self] message in
                self?.cardPresentPaymentInlineMessage = message
            })
            .store(in: &paymentSessionCancellables)

        // TTP cancel-on-reader → drop back to the idle hero. Synchronously closes
        // the gate, resets `paymentState.card` to `.idle`, and clears the inline
        // message in the same run loop the event arrives on, so a stray
        // `.tapSwipeOrInsertCard` arriving immediately after (or the previous
        // one's cached state) can't keep the "Tap card" message visible. The
        // actual Stripe cancel runs in a fire-and-forget Task — it's async, but
        // we don't need to wait for it before flipping back to the hero.
        cardPresentPaymentService.paymentEventPublisher
            .filter { event in
                if case .show(.cancelledOnReader) = event { return true }
                return false
            }
            .sink { [weak self] _ in
                guard let self, self.preferredConnectionMethod == .tapToPay else { return }
                self.isAwaitingExplicitPaymentStart = true
                self.currentPaymentMethod = nil
                self.paymentState.card = .idle
                self.cardPresentPaymentInlineMessage = nil
                Task { @MainActor [weak self] in
                    try? await self?.cardPresentPaymentService.cancelPayment()
                }
            }
            .store(in: &paymentSessionCancellables)

        // Payment events -> card payment state
        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent -> PointOfSaleCardPaymentState? in
                guard let self else { return nil }
                guard self.shouldPropagatePaymentEvent else { return nil }

                let newCardPaymentState = PointOfSaleCardPaymentState(from: paymentEvent,
                                                                      using: presentationStyleDeterminerDependencies)

                if case .acceptingCard = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderReady()
                }

                if case .processingPayment = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderTapped()
                }

                // On the TTP path Apple's modal owns the merchant's UX between
                // "Pay with Tap to pay" and a terminal event. Letting the
                // intermediate card states (validatingOrder / preparingReader /
                // acceptingCard / cardInserted / processingPayment) drive our
                // own card state is invisible while the modal is on screen,
                // but on cancel the modal dismisses faster than the
                // `cancelledOnReader` event arrives, and the merchant sees
                // our underlying "Tap card" / "Ready for payment" UI flash
                // for a frame. Suppress intermediates here — terminal states
                // (cardPaymentSuccessful / paymentError) still come through.
                // The cancel-on-reader path is handled by its dedicated
                // synchronous reset above. Gated on the *current session's*
                // method — when the merchant picks BT via the sheet on a
                // TTP-default device, BT events should drive the UI normally.
                if self.currentPaymentMethod == .tapToPay,
                   let state = newCardPaymentState {
                    switch state {
                    case .validatingOrder,
                            .preparingReader,
                            .acceptingCard,
                            .cardInserted,
                            .processingPayment:
                        return nil
                    case .idle,
                            .cardPaymentSuccessful,
                            .paymentError,
                            .validatingOrderError,
                            .paymentIntentCreationError:
                        break
                    }
                }

                return newCardPaymentState
            }
            .sink(receiveValue: { [weak self] cardPaymentState in
                guard let self else { return }
                if paymentState.cash != .idle {
                    if cardPaymentState.requiresCashExit {
                        DDLogWarn("💵 [CashPayment] committed card event \(cardPaymentState) during cash flow " +
                                  "- transitioning to card view")
                        paymentState.cash = .idle
                    } else {
                        DDLogInfo("💵 [CashPayment] ignoring non-committed card event \(cardPaymentState) during cash flow")
                        return
                    }
                }
                DDLogInfo("🃏 [CardPayment] subscription setting card state: \(cardPaymentState), " +
                          "current cash state: \(paymentState.cash)")
                paymentState.card = cardPaymentState
                // Don't auto-clear `currentPaymentMethod` on `.idle` — Stripe
                // emits `.idle` mid-cancel of a BT scan (before the merchant
                // is back at the hero), and clearing here woke up the
                // reader-reconnection observer, which then tried to TTP-
                // reconnect while the BT scan was still tearing down. That
                // race produced a `.scanningFailed` ("internal service error")
                // alert. Terminal-only clears: TTP cancel handles itself in
                // its dedicated handler, BT success / error fall through to
                // `reset()` when the merchant moves on, and a BT scan dismiss
                // leaves `currentPaymentMethod = .bluetooth` until the next
                // `startPayment(WithMethod)` overwrites it or `reset()` runs.
            })
            .store(in: &paymentSessionCancellables)
    }

    /// True when payment events are allowed to drive `cardPresentPaymentInlineMessage`
    /// and `paymentState.card`. On the BT path it's always true. On the TTP path it's
    /// false until the merchant explicitly taps a method, and re-armed back to false
    /// after a cancel-on-reader so transient events during the cancel teardown can't
    /// flicker the card state.
    var shouldPropagatePaymentEvent: Bool {
        guard preferredConnectionMethod == .tapToPay else { return true }
        return !isAwaitingExplicitPaymentStart
    }

    func mapCardPresentPaymentEventToMessageType(_ event: CardPresentPaymentEvent) -> PointOfSaleCardPresentPaymentMessageType? {
        // On the TTP path a merchant-cancelled-on-reader event drops the merchant
        // back to the idle hero rather than the legacy iPad "Payment canceled /
        // Try payment again" screen — Android does the same. Suppress the inline
        // message here; `handleCancelledOnReaderForTapToPay` resets card state.
        if preferredConnectionMethod == .tapToPay,
           case .show(.cancelledOnReader) = event {
            return nil
        }

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
        cancelConnectCardReaderTask()
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
