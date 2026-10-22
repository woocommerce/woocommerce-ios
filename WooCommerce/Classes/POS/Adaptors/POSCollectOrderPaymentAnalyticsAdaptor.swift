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
    private let catalogSyncStrategy: POSCheckoutCatalogStrategy
    private var checkoutSyncStrategy: POSCheckoutCatalogStrategy = .unknown
    private var checkoutStarted: Int?
    private var orderSyncCompleted: Int?
    private var paymentConfirmed: Int?

    private let analytics: POSAnalyticsProviding

    private let currentTimestamp: () -> TimeInterval
    private let monotonicMilliseconds: () -> Int

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
         catalogSyncStrategy: POSCheckoutCatalogStrategy = .unknown,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         currentTimestamp: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
         monotonicMilliseconds: (() -> Int)? = nil) {
        self.analytics = analytics
        self.catalogSyncStrategy = catalogSyncStrategy
        self.configuration = configuration
        self.currentTimestamp = currentTimestamp
        let origin = ContinuousClock.now
        self.monotonicMilliseconds = monotonicMilliseconds ?? {
            let elapsed = origin.duration(to: .now).components
            return Int(elapsed.seconds * 1000 + elapsed.attoseconds / 1_000_000_000_000_000)
        }
    }

    func prepareForCardPayment(order: POSPaymentAnalyticsOrder) {
        cardPaymentOrder = order
    }

    func clearPaymentConfirmation() {
        paymentConfirmed = nil
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
        trackProcessingCompletion(intent: intent, recordPaymentConfirmation: true)
    }

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent, recordPaymentConfirmation: Bool) {
        if recordPaymentConfirmation, checkoutStarted != nil, paymentConfirmed == nil {
            paymentConfirmed = monotonicMilliseconds()
        }
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

        trackPaymentEvent(.PointOfSale.cardPresentCollectPaymentSuccess(
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
            checkoutTapCount: checkoutTapCount
        ))

        clearPaymentConfirmation()
        resetCheckoutTapCountTracker()
        resetProcessingPaymentTracking()
    }

    func trackSuccessfulCashPayment(order: POSPaymentAnalyticsOrder) {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        trackPaymentEvent(.PointOfSale.cashCollectPaymentSuccess(
            order: order,
            countryCode: configuration.countryCode,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ), includeCardStages: false)
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
        resetCheckoutTiming()
    }

    func trackSuccessfulMarkAsPaidPayment(order: POSPaymentAnalyticsOrder) {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        analytics.track(event: .PointOfSale.markAsPaidSuccess(
            order: order,
            countryCode: configuration.countryCode,
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ))
        resetCheckoutTapCountTracker()
        resetCheckoutTiming()
    }

    func trackPaymentFailure(with error: any Error) {
        trackPaymentEvent(.PointOfSale.cardPresentCollectPaymentFailed(
            forGatewayID: paymentGatewayAccount?.gatewayID,
            error: error,
            countryCode: configuration.countryCode,
            cardReaderModel: connectedReaderModel,
            millisecondsSinceCustomerIteractionStarted: calculateElapsedTimeInMilliseconds(since: customerInteractionStarted),
            millisecondsSinceOrderSyncSuccess: calculateElapsedTimeInMilliseconds(since: orderSync),
            millisecondsSinceReaderReadyToCollect: calculateElapsedTimeInMilliseconds(since: cardReaderReady),
            millisecondsSinceCardTapped: calculateElapsedTimeInMilliseconds(since: cardReaderTapped),
            checkoutTapCount: checkoutTapCount
        ))
        clearPaymentConfirmation()

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
            checkoutTapCount: checkoutTapCount
        ))

        resetProcessingPaymentTracking()
    }

    func trackCustomerInteractionStarted() {
        // Any action that is considered as user starting an iteraction resets any ongoing counter
        resetAllCountersOnInteractionStarted()
        resetCheckoutTiming()
        analytics.track(.pointOfSaleInteractionWithCustomerStarted)
        customerInteractionStarted = currentTimestamp()
    }

    func trackOrderSyncSuccess() {
        orderSync = trackCurrentTime()
        if checkoutStarted != nil, orderSyncCompleted == nil {
            orderSyncCompleted = monotonicMilliseconds()
        }
    }

    func trackCardReaderReady() {
        cardReaderReady = trackCurrentTime()

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
        checkoutSyncStrategy = catalogSyncStrategy
        checkoutStarted = monotonicMilliseconds()
        orderSyncCompleted = nil
        clearPaymentConfirmation()
    }

    func resetCheckoutTiming() {
        checkoutSyncStrategy = .unknown
        checkoutStarted = nil
        orderSyncCompleted = nil
        clearPaymentConfirmation()
    }

    func resetCheckoutTapCountTracker() {
        checkoutTapCount = 0
    }

    private func trackElapsedTimeFromOrderSyncToCardReady() {
        let elapsedTime = calculateElapsedTimeInSeconds(from: orderSync, to: cardReaderReady)
        analytics.track(event: .PointOfSale.cardReaderReadyForCardPayment(waitingTime: elapsedTime))
    }
}

// Helpers
private extension POSCollectOrderPaymentAnalyticsAdaptor {
    func trackPaymentEvent(_ event: WooAnalyticsEvent, includeCardStages: Bool = true) {
        let end = monotonicMilliseconds()
        func elapsed(since start: Int?) -> Int? {
            guard let start, end >= start else { return nil }
            return end - start
        }
        analytics.track(event: .PointOfSale.withCheckoutTiming(
            event,
            syncStrategy: checkoutSyncStrategy,
            millisecondsSinceCheckoutStarted: elapsed(since: checkoutStarted),
            millisecondsSinceOrderSyncCompleted: elapsed(since: orderSyncCompleted),
            millisecondsSincePaymentConfirmed: includeCardStages ? elapsed(since: paymentConfirmed) : nil
        ))
    }

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
    }

    private func resetAllCountersOnInteractionStarted() {
        orderSync = 0
        cardReaderReady = 0
        cardReaderTapped = 0
        resetCheckoutTapCountTracker()
        resetProcessingPaymentTracking()
    }
}
