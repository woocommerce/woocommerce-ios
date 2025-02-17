import Yosemite

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    private var customerInteractionStarted: Double = 0
    private var orderCreated: Double = 0
    private var cardReaderReady: Double = 0
    private var cardReaderTapped: Double = 0
    private var checkoutTapCount: Int = 0

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

        ServiceLocator.analytics.track(event: .PointOfSale.cardPresentCollectPaymentSuccess(
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction,
            millisecondsSinceOrderCreationSuccess: elapsedTimeSinceOrderCreation,
            millisecondsSinceReaderReadyToCollect: elapsedTimeSinceCardReaderReady,
            millisecondsSinceCardTapped: elapsedTimeSinceCardTapped,
            checkoutTapCount: checkoutTapCount
        ))
    }

    func trackSuccessfulCashPayment() {
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(since: customerInteractionStarted)

        ServiceLocator.analytics.track(event: .PointOfSale.cashCollectPaymentSuccess(
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction
        ))
    }

    func trackPaymentFailure(with error: any Error) { }
    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) { }
    func trackEmailTapped() { }
    func trackReceiptPrintTapped() { }
    func trackReceiptPrintSuccess() { }
    func trackReceiptPrintCanceled() { }
    func trackReceiptPrintFailed(error: any Error) { }

    func trackCustomerInteractionStarted() {
        ServiceLocator.analytics.track(.pointOfSaleInteractionWithCustomerStarted)
        customerInteractionStarted = Date().timeIntervalSince1970
    }

    func trackOrderCreationSuccess() {
        orderCreated = trackCurrentTime()
    }

    func trackCardReaderReady() {
        cardReaderReady = trackCurrentTime()

        // As a side effect of knowing when the reader is ready, we track the elapsed from order creation
        trackElapsedTimeFromOrderCreationToCardReady()
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

    private func trackElapsedTimeFromOrderCreationToCardReady() {
        let elapsedTime = cardReaderReady - orderCreated
        ServiceLocator.analytics.track(event: .PointOfSale.cardReaderReadyForCardPayment(waitingTime: elapsedTime))
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
    func trackSuccessfulCashPayment() { }
}
