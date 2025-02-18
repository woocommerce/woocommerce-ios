import protocol WooFoundation.Analytics
import Yosemite

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    private var customerInteractionStarted: Double = 0
    private var orderCreated: Double = 0
    private var cardReaderReady: Double = 0
    private var cardReaderTapped: Double = 0
    private var checkoutTapCount: Int = 0

    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func preflightResultReceived(_ result: CardReaderPreflightResult?) { }
    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) { }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        // Property: milliseconds_since_customer_interaction_started
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        // Property: milliseconds_since_order_creation_success
        let elapsedTimeSinceOrderCreation = calculateElapsedTimeInMilliseconds(since: orderCreated)

        // Property: milliseconds_since_reader_ready_to_collect_payment
        let elapsedTimeSinceCardReaderReady = calculateElapsedTimeInMilliseconds(since: cardReaderReady)

        // Property: milliseconds_since_card_tapped
        let elapsedTimeSinceCardTapped = calculateElapsedTimeInMilliseconds(since: cardReaderTapped)

        analytics.track(event: .PointOfSale.cardPresentCollectPaymentSuccess(
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction,
            millisecondsSinceOrderCreationSuccess: elapsedTimeSinceOrderCreation,
            millisecondsSinceReaderReadyToCollect: elapsedTimeSinceCardReaderReady,
            millisecondsSinceCardTapped: elapsedTimeSinceCardTapped,
            checkoutTapCount: checkoutTapCount
        ))

        resetCheckoutTapCountTracker()
    }

    func trackPaymentFailure(with error: any Error) { }
    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) { }
    func trackEmailTapped() { }
    func trackReceiptPrintTapped() { }
    func trackReceiptPrintSuccess() { }
    func trackReceiptPrintCanceled() { }
    func trackReceiptPrintFailed(error: any Error) { }

    func trackCustomerInteractionStarted() {
        customerInteractionStarted = Date().timeIntervalSince1970
    }

    func trackOrderCreationSuccess() {
        orderCreated = trackCurrentTime()
    }

    func trackCardReaderReady() {
        cardReaderReady = trackCurrentTime()
    }

    func trackCardReaderTapped() {
        cardReaderTapped = trackCurrentTime()
    }

    func trackCheckoutTapped() {
        checkoutTapCount += 1
    }

    func resetCheckoutTapCountTracker() {
        checkoutTapCount = 0
    }
}

// Helpers
private extension POSCollectOrderPaymentAnalytics {
    func trackCurrentTime() -> Double {
        Date().timeIntervalSince1970
    }

    func calculateElapsedTimeInMilliseconds(since start: Double) -> Double {
        let end = Date().timeIntervalSince1970
        return floor((end - start) * 1000)
    }
}

// Protocol conformance. These events are not needed for IPP, only for POS.
// https://github.com/woocommerce/woocommerce-ios/issues/15149
extension CollectOrderPaymentAnalytics {
    func trackCustomerInteractionStarted() { }
    func trackOrderCreationSuccess() { }
    func trackCardReaderReady() { }
    func trackCardReaderTapped() { }
    func trackCheckoutTapped() { }
    func resetCheckoutTapCountTracker() { }
}
