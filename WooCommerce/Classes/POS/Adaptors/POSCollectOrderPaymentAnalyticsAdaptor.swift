import Foundation
import protocol WooFoundation.Analytics
import Yosemite
import PointOfSale

/// Overrides the default event tracking for card present payments on IPP in Order Creation flow
///
@MainActor
final class POSCollectOrderPaymentAnalyticsAdaptor: @MainActor POSCollectOrderPaymentAnalyticsTracking, CollectOrderPaymentAnalyticsTracking {
    private var cardPaymentOrder: POSPaymentAnalyticsOrder?
    private var customerInteractionStarted: Double = 0
    private var orderSync: Double = 0
    private var cardReaderReady: Double = 0
    private var cardReaderTapped: Double = 0
    private var checkoutTapCount: Int = 0
    private var hasTrackedProcessingPayment = false
    private var hasTrackedCardReaderReady = false
    /// Reader-ready stamp of the current payment attempt only. Cleared when an attempt starts or ends,
    /// so a retry never reports the previous attempt's preparation. `cardReaderReady` keeps its legacy lifetime.
    private var attemptCardReaderReady: Double = 0

    /// Latest reader connection status reported by POS. `nil` until the first status arrives, so an unknown state
    /// is never reported as disconnected.
    private var isCardReaderConnected: Bool?
    /// Whether a reader was connected when the current customer interaction started. `nil` before the first interaction.
    private var readerConnectedAtCheckout: Bool?
    /// When a reader connected during the current customer interaction, if it was not connected at its start.
    private var cardReaderConnected: Double = 0

    private let analytics: POSAnalyticsProviding

    private let currentTimestamp: () -> TimeInterval

    private var paymentGatewayAccount: PaymentGatewayAccount?
    private let configuration: CardPresentPaymentsConfiguration
    private var connectedReader: CardReader?
    var connectedReaderModel: String? {
        connectedReader?.readerType.model
    }

    private var readerTransport: String {
        switch connectedReader?.readerType {
        case .tapToPay:
            return "built_in"
        case .chipper, .stripeM2, .wisepad3:
            return "bluetooth"
        case .other, .none:
            return "unknown"
        }
    }

    init(analytics: POSAnalyticsProviding,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         currentTimestamp: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.analytics = analytics
        self.configuration = configuration
        self.currentTimestamp = currentTimestamp
    }

    func prepareForCardPayment(order: POSPaymentAnalyticsOrder) {
        cardPaymentOrder = order
        // A new collection starts here, before preflight, so an outcome reported before validation
        // (for example a cancelled preflight) can't carry an earlier attempt's reader-ready timing.
        resetCardReaderReadyForAttempt()
    }

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {
        switch result {
        case .completed(let connectedReader, let paymentGatewayAccount):
            self.connectedReader = connectedReader
            self.paymentGatewayAccount = paymentGatewayAccount
        case .canceled(_, let paymentGatewayAccount):
            self.connectedReader = nil
            self.paymentGatewayAccount = paymentGatewayAccount
        case .none:
            break
        }
    }

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) {
        guard let paymentMethod = intent.paymentMethod(),
              case .interacPresent = paymentMethod else {
            return
        }

        analytics.track(event: .PointOfSale.interacCollectPaymentSuccess(
            forGatewayID: paymentGatewayAccount?.gatewayID,
            countryCode: configuration.countryCode,
            cardReaderModel: connectedReaderModel
        ))
    }

    func trackSuccessfulCardPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        guard let order = cardPaymentOrder else { return }
        // Property: milliseconds_since_customer_interaction_started
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        // Property: milliseconds_since_order_sync_success
        let elapsedTimeSinceOrderSync = calculateElapsedTimeInMilliseconds(since: orderSync)

        // Property: milliseconds_since_reader_ready_to_collect_payment
        let elapsedTimeSinceCardReaderReady = calculateElapsedTimeInMilliseconds(since: cardReaderReady)

        // Property: milliseconds_since_card_tapped
        let elapsedTimeSinceCardTapped = calculateElapsedTimeInMilliseconds(since: cardReaderTapped)

        analytics.track(event: .PointOfSale.cardPresentCollectPaymentSuccess(
            forGatewayID: paymentGatewayAccount?.gatewayID,
            countryCode: configuration.countryCode,
            paymentMethod: capturedPaymentData.paymentMethod,
            cardReaderModel: connectedReaderModel,
            order: order,
            transport: readerTransport,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction,
            millisecondsSinceOrderSyncSuccess: elapsedTimeSinceOrderSync,
            millisecondsSinceReaderReadyToCollect: elapsedTimeSinceCardReaderReady,
            millisecondsSinceCardTapped: elapsedTimeSinceCardTapped,
            checkoutTapCount: checkoutTapCount,
            readerReadyTiming: readerReadyTiming()
        ))

        resetCheckoutTapCountTracker()
        resetProcessingPaymentTracking()
    }

    func trackSuccessfulCashPayment(order: POSPaymentAnalyticsOrder) {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        analytics.track(event: .PointOfSale.cashCollectPaymentSuccess(
            order: order,
            countryCode: configuration.countryCode,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ))
        resetCheckoutTapCountTracker()
    }

    func trackSuccessfulScanToPayPayment(order: POSPaymentAnalyticsOrder) {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        analytics.track(event: .PointOfSale.scanToPayCollectPaymentSuccess(
            order: order,
            countryCode: configuration.countryCode,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ))
        resetCheckoutTapCountTracker()
    }

    func trackSuccessfulMarkAsPaidPayment(order: POSPaymentAnalyticsOrder) {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        analytics.track(event: .PointOfSale.markAsPaidSuccess(
            order: order,
            countryCode: configuration.countryCode,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ))
        resetCheckoutTapCountTracker()
    }

    func trackPaymentFailure(with error: any Error) {
        analytics.track(event: .PointOfSale.cardPresentCollectPaymentFailed(
            forGatewayID: paymentGatewayAccount?.gatewayID,
            error: error,
            countryCode: configuration.countryCode,
            cardReaderModel: connectedReaderModel,
            millisecondsSinceCustomerIteractionStarted: calculateElapsedTimeInMilliseconds(since: customerInteractionStarted),
            millisecondsSinceOrderSyncSuccess: calculateElapsedTimeInMilliseconds(since: orderSync),
            millisecondsSinceReaderReadyToCollect: calculateElapsedTimeInMilliseconds(since: cardReaderReady),
            millisecondsSinceCardTapped: calculateElapsedTimeInMilliseconds(since: cardReaderTapped),
            checkoutTapCount: checkoutTapCount,
            readerReadyTiming: readerReadyTiming()
        ))

        // The checkout tap count is deliberately not reset:
        // the merchant can retry after a failure, and we want the count to reflect every attempt made for the same customer interaction.
        resetProcessingPaymentTracking()
    }

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        analytics.track(event: .PointOfSale.cardPresentCollectPaymentCanceled(
            forGatewayID: paymentGatewayAccount?.gatewayID,
            countryCode: configuration.countryCode,
            cardReaderModel: connectedReaderModel,
            cancellationSource: cancelationSource.rawValue,
            millisecondsSinceCustomerIteractionStarted: calculateElapsedTimeInMilliseconds(since: customerInteractionStarted),
            millisecondsSinceOrderSyncSuccess: calculateElapsedTimeInMilliseconds(since: orderSync),
            millisecondsSinceReaderReadyToCollect: calculateElapsedTimeInMilliseconds(since: cardReaderReady),
            millisecondsSinceCardTapped: calculateElapsedTimeInMilliseconds(since: cardReaderTapped),
            checkoutTapCount: checkoutTapCount,
            readerReadyTiming: readerReadyTiming()
        ))

        resetProcessingPaymentTracking()
    }

    func trackCustomerInteractionStarted() {
        // Any action that is considered as user starting an iteraction resets any ongoing counter
        resetAllCountersOnInteractionStarted()
        analytics.track(.pointOfSaleInteractionWithCustomerStarted)
        customerInteractionStarted = currentTimestamp()
        readerConnectedAtCheckout = isCardReaderConnected
    }

    func trackCardReaderConnectionChanged(isConnected: Bool) {
        let wasConnected = isCardReaderConnected
        isCardReaderConnected = isConnected

        // Only the first connection after an interaction that started without a reader counts as connection waiting.
        // The first status ever received is not a connection: it only tells us the current state.
        guard isConnected, wasConnected == false, readerConnectedAtCheckout == false, cardReaderConnected == 0 else {
            return
        }
        cardReaderConnected = currentTimestamp()
    }

    func trackCardPaymentAttemptStarted() {
        resetCardReaderReadyForAttempt()
    }

    func trackOrderSyncSuccess() {
        orderSync = trackCurrentTime()
    }

    // Only the first card input request of a payment attempt marks the reader as ready.
    // The flag is reset when an attempt starts or ends (success, failure or cancellation) and when a new interaction starts,
    // so a retry after a decline stamps again when the reader asks for a card again.
    func trackCardReaderReady() {
        guard !hasTrackedCardReaderReady else {
            return
        }
        hasTrackedCardReaderReady = true
        cardReaderReady = trackCurrentTime()
        attemptCardReaderReady = cardReaderReady

        // As a side effect of knowing when the reader is ready, we track the elapsed from order sync (created or updated)
        trackElapsedTimeFromOrderSyncToCardReady()
    }

    // The Stripe SDK returns multiple `.processing` events, but we want to capture the first one in the stream only.
    // This flag is reset as soon as the payment has been successful
    func trackCardReaderTapped() {
        if !hasTrackedProcessingPayment {
            hasTrackedProcessingPayment = true
            cardReaderTapped = trackCurrentTime()
        }
    }

    func trackCheckoutTapped() {
        checkoutTapCount += 1
    }

    func resetCheckoutTapCountTracker() {
        checkoutTapCount = 0
    }

    private func trackElapsedTimeFromOrderSyncToCardReady() {
        let elapsedTime = calculateElapsedTimeInSeconds(from: orderSync, to: cardReaderReady)
        analytics.track(event: .PointOfSale.cardReaderReadyForCardPayment(waitingTime: elapsedTime,
                                                                          readerReadyTiming: readerReadyTiming()))
    }

    private func readerReadyTiming() -> WooAnalyticsEvent.PointOfSale.ReaderReadyTiming {
        // Preparation starts at order sync, or later if the reader only connected after it,
        // so time spent waiting for a connection is not counted as preparation.
        let preparationStart = max(orderSync, cardReaderConnected)
        let millisecondsFromOrderSyncToReaderReady: Double? = orderSync > 0 && attemptCardReaderReady >= preparationStart
            ? floor((attemptCardReaderReady - preparationStart) * 1000)
            : nil
        let millisecondsWaitingForReaderConnection: Double? = customerInteractionStarted > 0 && cardReaderConnected > 0
            ? floor((cardReaderConnected - customerInteractionStarted) * 1000)
            : nil

        return WooAnalyticsEvent.PointOfSale.ReaderReadyTiming(
            readerConnectedAtCheckout: readerConnectedAtCheckout,
            millisecondsWaitingForReaderConnection: millisecondsWaitingForReaderConnection,
            millisecondsFromOrderSyncToReaderReady: millisecondsFromOrderSyncToReaderReady,
            readerReadySignal: attemptCardReaderReady > 0 ? .inputRequested : nil
        )
    }
}

// Helpers
private extension POSCollectOrderPaymentAnalyticsAdaptor {
    func trackCurrentTime() -> Double {
        currentTimestamp()
    }

    func calculateElapsedTimeInMilliseconds(since start: Double) -> Double {
        guard start > 0 else {
            return 0
        }

        let end = currentTimestamp()
        return floor((end - start) * 1000)
    }

    /// Both markers are Unix timestamps: subtracting an unset one reports the wall clock as if it were a duration.
    func calculateElapsedTimeInSeconds(from start: Double, to end: Double) -> Double {
        guard start > 0, end > 0 else {
            return 0
        }

        return end - start
    }

    private func resetProcessingPaymentTracking() {
        hasTrackedProcessingPayment = false
        resetCardReaderReadyForAttempt()
    }

    private func resetCardReaderReadyForAttempt() {
        hasTrackedCardReaderReady = false
        attemptCardReaderReady = 0
    }

    private func resetAllCountersOnInteractionStarted() {
        orderSync = 0
        cardReaderReady = 0
        cardReaderTapped = 0
        cardReaderConnected = 0
        resetCheckoutTapCountTracker()
        resetProcessingPaymentTracking()
    }
}
