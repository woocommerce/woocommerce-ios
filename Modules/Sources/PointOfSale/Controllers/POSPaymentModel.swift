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

    /// The connection method of the currently active payment session, or nil
    /// between sessions. Distinct from `preferredConnectionMethod` (the POS
    /// session's default): the merchant can pick BT via the "Other payment
    /// methods" sheet on a TTP-default device, in which case the active
    /// session is `.bluetooth` even though preferred remains `.tapToPay`.
    /// This is the field that gates the intermediate-state filter and the
    /// model-side re-entry guard.
    private(set) var currentPaymentMethod: CardReaderConnectionMethod?

    /// The method of the reader Stripe Terminal currently has connected — or
    /// nil if no reader is connected. Distinct from `currentPaymentMethod`
    /// (which tracks an in-flight *payment session*); this one persists
    /// across `reset()` because the underlying SDK connection persists across
    /// our payment-model lifecycle too. Used in `connectTapToPayReader` to
    /// skip the defensive disconnect-first when the reader is already TTP —
    /// otherwise every checkout re-entry forces an unnecessary
    /// disconnect-then-reconnect cycle and surfaces the "Preparing Tap to
    /// Pay…" indicator each time.
    private(set) var lastConnectedMethod: CardReaderConnectionMethod?

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
    private let scanToPayHandler: POSScanToPayHandling
    /// Optional so non-cart flows (e.g. bookings) can opt out of polling — without a verifier
    /// the model still works for the merchant-confirmed-via-Done path.
    private let scanToPayVerifier: POSScanToPayVerifying?
    private let markAsPaidHandler: POSMarkAsPaidHandling
    private let receiptSender: POSReceiptSending
    private let postPaymentStep: (() async throws -> Void)?
    let configuration: POSPaymentFlowConfiguration
    private let analytics: POSAnalyticsProviding
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let celebration: PaymentCaptureCelebrationProtocol
    /// Cadence for scan-to-pay polling. Defaults to 3 seconds; tests override to fire instantly.
    private let scanToPayPollInterval: TimeInterval

    /// The reader connection method this POS session should use as its default.
    ///
    /// `.bluetooth` (iPad / phone without TTP eligibility) keeps the classic
    /// auto-collect-on-connect behaviour: when the merchant enters checkout
    /// `startPayment()` waits for any BT reader to come up and collects via that.
    /// `.tapToPay` (phone with TTP eligibility) only pre-connects the built-in
    /// reader on checkout — collection is gated behind an explicit method tap
    /// from the buttons row / hero via `startPaymentWithMethod(_:)`, so the
    /// merchant's selection drives which method actually runs.
    private let preferredConnectionMethod: CardReaderConnectionMethod

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
    /// QR-encodeable URL for the active scan-to-pay payment. Populated lazily when the
    /// merchant taps Scan to Pay (after promoting the autoDraft to `.pending`).
    private(set) var scanToPayURL: URL?
    /// True while `provideOrderForScanToPay()` is in flight. Lets the QR view distinguish
    /// "still loading the URL" from "no URL available".
    private(set) var isPreparingScanToPay: Bool = false
    private var scanToPayPollingTask: Task<Void, Never>?

    /// Coalesces concurrent silent-TTP pre-connect attempts. Without this,
    /// every call to `connectTapToPayReader` (which can come from
    /// `startPayment` on checkout entry, `observeReaderReconnection` firing
    /// on a `.disconnected` event, and re-registrations after back-to-cart
    /// cycles) kicks off its own `connectReader` Task. Stripe Terminal
    /// serialises them but the race adds significant latency to the first
    /// successful connect.
    private var tapToPayConnectTask: Task<Void, Never>?

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         orderProvider: POSPaymentOrderProviding,
         cashPaymentHandler: POSCashPaymentHandling,
         scanToPayHandler: POSScanToPayHandling,
         scanToPayVerifier: POSScanToPayVerifying? = nil,
         markAsPaidHandler: POSMarkAsPaidHandling,
         receiptSender: POSReceiptSending,
         postPaymentStep: (() async throws -> Void)? = nil,
         configuration: POSPaymentFlowConfiguration,
         analytics: POSAnalyticsProviding,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration(),
         scanToPayPollInterval: TimeInterval = 3,
         preferredConnectionMethod: CardReaderConnectionMethod = .bluetooth,
         paymentState: PointOfSalePaymentState = .idle) {
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderProvider = orderProvider
        self.cashPaymentHandler = cashPaymentHandler
        self.scanToPayHandler = scanToPayHandler
        self.scanToPayVerifier = scanToPayVerifier
        self.markAsPaidHandler = markAsPaidHandler
        self.receiptSender = receiptSender
        self.postPaymentStep = postPaymentStep
        self.configuration = configuration
        self.analytics = analytics
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.celebration = celebration
        self.scanToPayPollInterval = scanToPayPollInterval
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
            // One-shot Bluetooth cleanup. Each new order on phone POS
            // returns to the TTP hero — we do **not** auto-resume Bluetooth
            // across orders, even if the BT reader is still attached from
            // the previous transaction. If a merchant wants BT for the next
            // order, they re-pick "Card reader" from the Other payment
            // methods sheet. This deliberately keeps the state machine
            // simple: every checkout entry begins from a clean TTP-pre-
            // connect baseline, eliminating the mid-flow auto-resume and
            // method-switch surface that produced the foundReader race +
            // state-drift issues in earlier iterations.
            if lastConnectedMethod == .bluetooth,
               case .connected = cardReaderConnectionStatus {
                DDLogInfo("🃏 [CardPayment] Phone POS one-shot BT: dropping BT reader before TTP pre-connect")
                await cardPresentPaymentService.disconnectReader()
            }
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
        DDLogInfo("🃏 [CardPayment] startPaymentWithMethod \(method) — status: \(cardReaderConnectionStatus), "
                  + "currentPaymentMethod: \(String(describing: currentPaymentMethod))")

        // Same-method re-entry guard. Two different shapes:
        // - BT: card state moves out of `.idle` during collection, so the
        //   currentPaymentMethod check catches re-entry too.
        // - TTP: we suppress intermediate card states so `paymentState.card`
        //   stays `.idle` for the whole session — `currentPaymentMethod` is
        //   the canonical "in flight" check.
        if currentPaymentMethod == method {
            DDLogInfo("🃏 [CardPayment] startPaymentWithMethod ignored — \(method) session already active")
            return
        }
        // Block re-entry while non-idle if there's no active method to switch
        // *from* (stray closure / SwiftUI re-render after a terminal state).
        if paymentState.card != .idle, currentPaymentMethod == nil {
            DDLogInfo("🃏 [CardPayment] startPaymentWithMethod ignored — non-idle card state with no active method")
            return
        }

        // Method-switch path: the merchant is switching from one active
        // method to another (e.g. picking Tap to Pay from the Other Payment
        // Methods sheet while a BT reader is mid-collection). Cancel the
        // in-flight collection on the SDK before we tear down the reader —
        // otherwise the new collect would race with a still-pending one and
        // Stripe Terminal would reject it.
        if let active = currentPaymentMethod, active != method {
            DDLogInfo("🃏 [CardPayment] startPaymentWithMethod switching \(active) -> \(method) — cancelling current payment first")
            do {
                try await cardPresentPaymentService.cancelPayment()
            } catch {
                DDLogError("🃏 [CardPayment] cancelPayment on method switch failed: \(error)")
            }
        }

        // When switching to Bluetooth from a TTP-pre-connect-in-flight state
        // (merchant tapped Card reader before the silent pre-connect had
        // settled), **wait** for the pre-connect Task to finish before
        // starting the BT scan. Crucially this is a wait, not a cancel —
        // letting the SDK complete its in-flight `connectReader(.tapToPay)`
        // cleanly avoids the foundReader race where a still-tearing-down
        // TTP reader briefly appears in the subsequent BT discovery results
        // (the "Found [hex]" flash we kept hitting). Cost: ~1-2s of perceived
        // latency if the merchant taps Card reader very early on entry.
        if method == .bluetooth, let task = tapToPayConnectTask {
            DDLogInfo("🃏 [CardPayment] BT pick waiting for in-flight TTP pre-connect to finish")
            _ = await task.value
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

        // If a reader is connected via a *different* method than the one the
        // merchant just picked, disconnect it first. Stripe Terminal can only
        // hold one active reader, so the subsequent connect would be rejected
        // otherwise. `lastConnectedMethod` is the canonical "what method is
        // currently connected" signal — distinct from `preferredConnectionMethod`
        // which is the POS-level default and doesn't track what's actually
        // attached right now. (The previous check used `preferredConnectionMethod`
        // and missed phone-POS-with-BT-currently-attached cases.)
        if case .connected = cardReaderConnectionStatus, lastConnectedMethod != method {
            await cardPresentPaymentService.disconnectReader()
        }

        if case .disconnected = cardReaderConnectionStatus {
            // Skip the explicit connect if the silent TTP pre-connect is
            // already running — status stays `.disconnected` for the entire
            // duration of a Stripe Terminal `connectReader` call (there is no
            // intermediate `.connecting` case), so the only way to know
            // "connect already in flight" is the `tapToPayConnectTask` guard.
            // Without this, tapping the hero CTA before pre-connect has
            // finished fires a *second* concurrent `connectReader(.tapToPay)`,
            // which the SDK can't reconcile — the connect errors out, status
            // never reaches `.connected`, and the `startPaymentFlow`
            // one-shot subscription that's about to be set up never fires.
            // The merchant sees the CTA spin forever and the TTP modal never
            // appears. We let the existing pre-connect Task drive the connect;
            // `startPaymentFlow` will subscribe to `.connected` and collect as
            // soon as the pre-connect Task completes.
            if method == .tapToPay, tapToPayConnectTask != nil {
                DDLogInfo("🃏 [CardPayment] tap during pre-connect — letting existing pre-connect drive the connect")
            } else {
                Task { @MainActor [weak self] in
                    do {
                        _ = try await self?.cardPresentPaymentService.connectReader(using: method)
                        self?.lastConnectedMethod = method
                    } catch {
                        DDLogWarn("🃏 [CardPayment] explicit connect via \(method) failed: \(error)")
                    }
                }
            }
        }

        await startPaymentFlow(using: method)
    }

    /// Pre-connects the built-in Tap to Pay reader without starting collection.
    /// Called from `startPayment()` when `preferredConnectionMethod == .tapToPay`,
    /// so the reader is warm by the time the merchant taps the hero CTA.
    func connectTapToPayReader() {
        // Coalesce — if a pre-connect Task is already in flight, this is a
        // no-op. Without this, `startPayment` being called multiple times
        // during checkout entry (once via `checkOut`, again via
        // `observeReaderReconnection` firing on the first transient
        // disconnect) stacks up redundant `connectReader` Tasks that
        // serialise inside Stripe Terminal and visibly delay the first
        // successful connect.
        guard tapToPayConnectTask == nil else { return }
        tapToPayConnectTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.tapToPayConnectTask = nil }
            // Reader already connected via TTP — nothing to do. Re-entering
            // checkout after a successful payment or after going back to
            // edit the cart used to force an unnecessary disconnect-then-
            // reconnect cycle here, surfacing the "Preparing Tap to Pay…"
            // indicator every time.
            if case .connected = cardReaderConnectionStatus,
               lastConnectedMethod == .tapToPay {
                return
            }
            // Stripe Terminal can only hold one active reader. If a *different*
            // reader is still attached (a stale BT reader from a previous
            // session, or no record of what method it was), connecting on top
            // would fail with "another reader is already connected" — for a
            // connect the merchant didn't even ask for. Drop it first.
            if case .connected = cardReaderConnectionStatus {
                await cardPresentPaymentService.disconnectReader()
            }
            do {
                _ = try await cardPresentPaymentService.connectReader(using: .tapToPay)
                lastConnectedMethod = .tapToPay
            } catch {
                DDLogWarn("🃏 [CardPayment] silent TTP pre-connect failed: \(error)")
            }
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
        do {
            try await cardPresentPaymentService.cancelPayment()
        } catch {
            DDLogError("🃏 [CardPayment] cancelPayment before collect failed: \(error)")
        }
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

        do {
            try await cardPresentPaymentService.cancelPayment()
        } catch {
            DDLogError("🃏 [CardPayment] cancelPayment before retry-collect failed: \(error)")
        }

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
            do {
                _ = try await self?.cardPresentPaymentService.connectReader(using: .bluetooth)
                self?.lastConnectedMethod = .bluetooth
            } catch {
                DDLogWarn("🃏 [CardPayment] BT connect failed: \(error)")
            }
        }
    }

    func cancelReconnection() {
        Task { @MainActor [weak self] in
            await self?.cardPresentPaymentService.cancelReconnection()
            // Belt-and-suspenders: the SDK's `cancelReconnection` has an
            // early-return path when its internal `reconnectionCancelable` is
            // already nil or completed. In that path the Hardware layer sends
            // `.idle` to the reconnection-state subject but does *not* clear
            // the connected-readers subject, so `cardReaderConnectionStatus`
            // can stay at `.reconnecting` and the "Reconnecting reader…"
            // screen never transitions away. Explicit disconnect forces the
            // status to `.disconnected` so the UI can fall back to the TTP
            // hero (or the iPad disconnect message). Disconnect on an
            // already-disconnected reader is a no-op at the SDK level.
            await self?.cardPresentPaymentService.disconnectReader()
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

// MARK: - Scan to Pay
extension POSPaymentModel {
    /// Stage 1: merchant tapped Scan to Pay. Flips state immediately so the navigation
    /// destination pushes the QR screen now (the view shows a loading spinner while the
    /// promote network call is in flight). When the call returns, `scanToPayURL` is
    /// populated and polling begins.
    func startScanToPayPayment() async {
        guard paymentState.scanToPay == .idle else { return }
        guard paymentState.allowsScanToPayPayment else { return }

        DDLogInfo("📲 [ScanToPay] startScanToPayPayment called - card state: \(paymentState.card)")
        analytics.track(.pointOfSaleCheckoutScanToPayPaymentTapped)

        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        startPaymentGeneration += 1

        // Flip state right away so the dashboard observer pushes the QR screen.
        scanToPayURL = nil
        isPreparingScanToPay = true
        paymentState.scanToPay = .showingQRCode(verification: .waiting)

        cardPaymentCancelTask = Task { [weak self] in
            do {
                try await self?.cardPresentPaymentService.cancelPayment()
            } catch {
                DDLogWarn("📲 [ScanToPay] failed to cancel card payment: \(error)")
            }
        }

        do {
            // Promotes the autoDraft to `.pending` so the WC backend populates `payment_url`.
            // Mirrors what the order-creation flow already does at the equivalent step.
            let paymentOrder = try await orderProvider.provideOrderForScanToPay()

            // Bail if the merchant cancelled while we were waiting for the network.
            guard paymentState.scanToPay.isShowingQRCode else {
                isPreparingScanToPay = false
                return
            }

            currentOrder = paymentOrder.order
            formattedOrderTotalPrice = paymentOrder.formattedTotal
            scanToPayURL = paymentOrder.paymentURL
            isPreparingScanToPay = false

            // Only start polling once the order is actually pending — otherwise the verifier
            // would always classify the autoDraft as pending and burn API calls for nothing.
            startScanToPayPolling()
        } catch {
            DDLogError("📲 [ScanToPay] failed to provide order: \(error)")
            isPreparingScanToPay = false
            // Leave state as `.showingQRCode` so the view can render an "unable to generate"
            // message — same UX as if the backend returned no payment URL.
        }
    }

    /// Stage 2 (cancel): merchant tapped back. Resets state and re-arms the card flow.
    func cancelScanToPayPayment() async {
        analytics.track(.pointOfSaleBackToCheckoutFromScanToPayTapped)
        stopScanToPayPolling()
        paymentState.scanToPay = .idle
        paymentState.card = .idle
        scanToPayURL = nil
        isPreparingScanToPay = false
        cardPresentPaymentInlineMessage = nil

        await cardPaymentCancelTask?.value
        cardPaymentCancelTask = nil

        await startPayment()
    }

    /// Stage 2 (manual confirm): merchant tapped "I've received the payment". Adds an order
    /// note and transitions to success. Used when the gateway webhook hasn't fired yet but
    /// the merchant verified the payment out-of-band.
    func completeScanToPayPayment() async throws {
        let order: Order
        if let currentOrder {
            order = currentOrder
        } else {
            let paymentOrder = try await orderProvider.provideOrder()
            order = paymentOrder.order
            currentOrder = order
        }
        try await scanToPayHandler.completeScanToPayPayment(for: order)
        try? await postPaymentStep?()
        scanToPayPaymentSuccess()
    }

    private func scanToPayPaymentSuccess() {
        stopScanToPayPolling()
        paymentState.scanToPay = .paymentSuccess
        collectOrderPaymentAnalyticsTracker.trackSuccessfulScanToPayPayment()
        celebration.celebrate()
    }

    /// Polls the backend for the current order. When the gateway webhook flips it to a paid
    /// status, the success path runs automatically — no merchant tap required. Polling stops
    /// when the merchant cancels, the view goes away, or success fires.
    private func startScanToPayPolling() {
        guard scanToPayPollingTask == nil else { return }
        guard let scanToPayVerifier else { return }
        let interval = scanToPayPollInterval
        scanToPayPollingTask = Task { [weak self, scanToPayVerifier] in
            // Initial wait before first poll so we don't spam the API the moment the QR appears.
            try? await Task.sleep(nanoseconds: UInt64(interval * Double(NSEC_PER_SEC)))

            while !Task.isCancelled {
                guard let self else { return }

                // Bail if the merchant left scan-to-pay (cancelled or moved to success).
                let stillShowing = await MainActor.run { self.paymentState.scanToPay.isShowingQRCode }
                guard stillShowing else { return }

                do {
                    let result = try await scanToPayVerifier.checkPaymentStatus()

                    // Recheck cancellation + state AFTER the network call. The merchant may
                    // have tapped back while the request was in flight; without this guard
                    // we'd write `.showingQRCode(.waiting)` into state and resurrect the
                    // navigation push the dashboard observer is listening for.
                    if Task.isCancelled { return }
                    let stillShowingAfterCall = await MainActor.run { self.paymentState.scanToPay.isShowingQRCode }
                    guard stillShowingAfterCall else { return }

                    switch result {
                    case .paid:
                        await MainActor.run { self.handleScanToPayDetectedPayment() }
                        return
                    case .pending:
                        await MainActor.run {
                            // Re-check on the main actor to avoid a TOCTOU race against `stop`.
                            guard self.paymentState.scanToPay.isShowingQRCode else { return }
                            self.paymentState.scanToPay = .showingQRCode(verification: .waiting)
                        }
                    }
                } catch {
                    DDLogWarn("📲 [ScanToPay] verification poll failed: \(error)")

                    if Task.isCancelled { return }
                    let stillShowingAfterError = await MainActor.run { self.paymentState.scanToPay.isShowingQRCode }
                    guard stillShowingAfterError else { return }

                    await MainActor.run {
                        guard self.paymentState.scanToPay.isShowingQRCode else { return }
                        self.paymentState.scanToPay = .showingQRCode(verification: .error)
                    }
                }

                try? await Task.sleep(nanoseconds: UInt64(interval * Double(NSEC_PER_SEC)))
            }
        }
    }

    private func stopScanToPayPolling() {
        scanToPayPollingTask?.cancel()
        scanToPayPollingTask = nil
    }

    /// Backend confirmed the customer paid via the gateway. Skip the manual handler (no need
    /// to add a "merchant marked it paid" note) and transition straight to success.
    private func handleScanToPayDetectedPayment() {
        guard paymentState.scanToPay.isShowingQRCode else { return }
        analytics.track(.pointOfSaleScanToPayPaymentDetectedViaPolling)
        paymentState.scanToPay = .showingQRCode(verification: .confirming)
        Task { @MainActor [weak self] in
            try? await self?.postPaymentStep?()
            self?.scanToPayPaymentSuccess()
        }
    }
}

// MARK: - Mark Order as Paid
extension POSPaymentModel {
    /// Stage 1: merchant tapped "Mark order as paid" — show the confirmation alert.
    /// The actual order update happens in `confirmMarkAsPaidPayment()`; this just transitions
    /// state so the dashboard can present the alert and we can cancel any in-flight card payment.
    func startMarkAsPaidPayment() {
        guard paymentState.markAsPaid == .idle else { return }
        guard paymentState.allowsMarkAsPaidPayment else { return }

        DDLogInfo("🪙 [MarkAsPaid] startMarkAsPaidPayment called - card state: \(paymentState.card)")
        analytics.track(.pointOfSaleCheckoutMarkAsPaidTapped)

        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        startPaymentGeneration += 1

        paymentState.markAsPaid = .confirming

        cardPaymentCancelTask = Task { [weak self] in
            do {
                try await self?.cardPresentPaymentService.cancelPayment()
            } catch {
                DDLogWarn("🪙 [MarkAsPaid] failed to cancel card payment: \(error)")
            }
        }
    }

    /// Stage 2 (cancel): merchant declined the confirmation. Re-arms the card flow so they can
    /// fall back to a different payment method without restarting checkout.
    func cancelMarkAsPaidPayment() async {
        analytics.track(.pointOfSaleBackToCheckoutFromMarkAsPaidTapped)
        paymentState.markAsPaid = .idle
        paymentState.card = .idle
        // Mirror `cancelCashPayment`: clear any stale "Tap, swipe, or insert card" message that
        // was published before the merchant entered the mark-as-paid flow. The card subscription
        // will repopulate it once the reader publishes a fresh event.
        cardPresentPaymentInlineMessage = nil

        await cardPaymentCancelTask?.value
        cardPaymentCancelTask = nil

        await startPayment()
    }

    /// Stage 2 (confirm): merchant confirmed; mark the order as paid through the order
    /// controller. On failure rolls back to the confirmation stage so the merchant can retry.
    /// Analytics for failures fires here (not in the controller) so every failure path —
    /// `provideOrder()` and the handler call alike — funnels through one event.
    ///
    /// - Parameter note: Optional merchant-supplied free-form note captured by the
    ///   confirmation view (e.g. "Bank transfer from Maria"). Forwarded to the handler so it
    ///   can be attached to the order as a private order note for reconciliation context.
    func confirmMarkAsPaidPayment(note: String? = nil) async throws {
        do {
            let order: Order
            if let currentOrder {
                order = currentOrder
            } else {
                let paymentOrder = try await orderProvider.provideOrder()
                order = paymentOrder.order
                currentOrder = order
            }
            analytics.track(.pointOfSaleMarkAsPaidConfirmed)
            paymentState.markAsPaid = .processing
            try await markAsPaidHandler.markOrderAsPaid(for: order, note: note)
            try? await postPaymentStep?()
            markAsPaidPaymentSuccess()
        } catch {
            // Roll back so the merchant can try again or cancel.
            paymentState.markAsPaid = .confirming
            analytics.track(.pointOfSaleMarkAsPaidFailed)
            throw error
        }
    }

    private func markAsPaidPaymentSuccess() {
        paymentState.markAsPaid = .paymentSuccess
        collectOrderPaymentAnalyticsTracker.trackSuccessfulMarkAsPaidPayment()
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
        stopScanToPayPolling()
        cancelReaderPreparation()
    }

    /// Reactivates this payment model when it returns to the foreground.
    /// For card payments, restarts the full payment flow (cancel + collect).
    /// For cash, scan-to-pay, and mark-as-paid, restores session event subscriptions without
    /// activating the reader. If the QR was on screen, resumes polling.
    func activate() async {
        DDLogInfo("▶️ [Session] activate called — isActive: \(isActive), " +
                  "activeMethod: \(paymentState.activePaymentMethod), card: \(paymentState.card), " +
                  "cash: \(paymentState.cash), scanToPay: \(paymentState.scanToPay)")
        guard !isActive else { return }
        if paymentState.activePaymentMethod == .card {
            await startPayment()
        } else {
            subscribeToPaymentSessionEvents()
            if paymentState.scanToPay.isShowingQRCode {
                startScanToPayPolling()
            }
        }
    }
}

// MARK: - Reset
extension POSPaymentModel {
    func reset() {
        cancelConnectCardReaderTask()
        stopScanToPayPolling()
        paymentSessionCancellables.removeAll()
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
        currentOrder = nil
        formattedOrderTotalPrice = nil
        scanToPayURL = nil
        isPreparingScanToPay = false
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
            // Dedup before the switch — Stripe Terminal can emit multiple
            // identical status values in succession (e.g., during teardown /
            // re-init). Without this, a duplicate `.connected` re-kicks
            // `startPayment` (BT auto-resume branch), and a duplicate
            // `.disconnected` re-kicks the silent TTP pre-connect. Either
            // races the previous run. The `tapToPayConnectTask` coalesce on
            // the pre-connect side catches most of the pre-connect waste, but
            // de-duping here also short-circuits the redundant `startPayment`
            // hop entirely.
            .removeDuplicates()
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    // Both branches below are scoped to "no active session" —
                    // if a session is in flight (e.g. a BT-via-sheet pick on
                    // a TTP-default device deliberately disconnected TTP
                    // first), the session manages its own reconnect and we
                    // should stay out of the way — otherwise we race the
                    // session's chosen method and confuse the SDK.
                    guard self.currentPaymentMethod == nil else { return }
                    switch status {
                    case .disconnected:
                        // "Reader fell off the device" — re-enter the
                        // checkout default (silent TTP pre-connect on phone
                        // POS, BT auto-collect on iPad).
                        await self.startPayment()
                    case .connected:
                        // The reader came back up after a transient drop
                        // (`.reconnecting -> .connected` or
                        // `.disconnected -> .connected` via Settings). When
                        // the merchant had previously committed to BT, kick
                        // `startPayment` so the auto-resume path can re-run
                        // collect — otherwise the totals view lands in the
                        // dead state where `useTapToPayHeroLayout` is
                        // suppressed (BT connected) but no `PaymentViewContent`
                        // / bottom strip surfaces either, leaving the
                        // merchant with no actionable UI.
                        if self.lastConnectedMethod == .bluetooth {
                            await self.startPayment()
                        }
                    case .cancellingConnection, .disconnecting, .reconnecting:
                        break
                    }
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
                    // Clear the tracking flag so the next pre-connect can't
                    // mistakenly think a TTP reader is still attached and
                    // skip its own connect.
                    lastConnectedMethod = nil
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
        //
        // ⚠️ SUBSCRIPTION ORDER IS LOAD-BEARING — DO NOT REORDER ⚠️
        // This sink MUST be subscribed before the "Payment events -> card payment state"
        // sink below. Combine delivers to subscribers in subscription order. When a
        // `cancelledOnReader` event arrives, both sinks receive it synchronously in the
        // same run loop. The gate (`isAwaitingExplicitPaymentStart`) must flip to `true`
        // HERE, before the card-state sink evaluates `shouldPropagatePaymentEvent` — so
        // that sink short-circuits and does NOT overwrite `paymentState.card`. Reversing
        // the order would let the card-state sink run first, advancing state to e.g.
        // `.acceptingCard` for a frame before this sink resets it to `.idle`.
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
                    do {
                        try await self?.cardPresentPaymentService.cancelPayment()
                    } catch {
                        DDLogError("🃏 [CardPayment] cancelPayment on cancelledOnReader failed: \(error)")
                    }
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
                            .cardInserted:
                        return nil
                    case .processingPayment,
                            .idle,
                            .cardPaymentSuccessful,
                            .paymentError,
                            .validatingOrderError,
                            .paymentIntentCreationError:
                        // `.processingPayment` is intentionally let through on
                        // TTP so the brief window between Apple's modal closing
                        // and the success card rendering shows the inline
                        // "Processing payment" message via `PaymentViewContent`
                        // — matches what the BT reader path does, and avoids
                        // the merchant seeing the hero with its spinner-in-
                        // button as the "back to checkout" intermediate.
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
                if paymentState.scanToPay != .idle {
                    if cardPaymentState.requiresCashExit {
                        DDLogWarn("📲 [ScanToPay] committed card event \(cardPaymentState) during scan-to-pay flow " +
                                  "- transitioning to card view")
                        stopScanToPayPolling()
                        paymentState.scanToPay = .idle
                        scanToPayURL = nil
                        isPreparingScanToPay = false
                    } else {
                        DDLogInfo("📲 [ScanToPay] ignoring non-committed card event \(cardPaymentState) during scan-to-pay flow")
                        return
                    }
                }
                if paymentState.markAsPaid != .idle {
                    if cardPaymentState.requiresCashExit {
                        DDLogWarn("🪙 [MarkAsPaid] committed card event \(cardPaymentState) during mark-as-paid flow " +
                                  "- transitioning to card view")
                        paymentState.markAsPaid = .idle
                    } else {
                        // Verbose: the merchant can sit on the confirmation alert for a while;
                        // every reader event would otherwise be logged repeatedly.
                        DDLogVerbose("🪙 [MarkAsPaid] ignoring non-committed card event \(cardPaymentState) during mark-as-paid flow")
                        return
                    }
                }
                DDLogInfo("🃏 [CardPayment] subscription setting card state: \(cardPaymentState), " +
                          "current cash state: \(paymentState.cash), " +
                          "current scanToPay state: \(paymentState.scanToPay), " +
                          "current markAsPaid state: \(paymentState.markAsPaid)")
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
        // message here; the cancelledOnReader sink in subscribeToPaymentSessionEvents resets card state.
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
        stopScanToPayPolling()
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
