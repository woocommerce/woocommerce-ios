import Yosemite

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    private var customerInteractionStarted: Double = 0
    private var orderCreated: Double = 0
    private var cardReaderReady: Double = 0
    private var cardReaderTapped: Double = 0

    func preflightResultReceived(_ result: CardReaderPreflightResult?) { }
    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) { }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        // 1. milliseconds_since_customer_interaction_started
        let elapsedTimeSinceCustomerInteraction = calculateElapsedTimeInMilliseconds(start: customerInteractionStarted,
                                                                                     end: Date().timeIntervalSince1970)

        // 2. milliseconds_since_order_creation_success
        let elapsedTimeSinceOrderCreation = calculateElapsedTimeInMilliseconds(start: orderCreated,
                                                                               end: Date().timeIntervalSince1970)

        // 3. milliseconds_since_reader_ready_to_collect_payment
        let elapsedTimeSinceCardReaderReady = calculateElapsedTimeInMilliseconds(start: cardReaderReady,
                                                                                 end: Date().timeIntervalSince1970)

        // 4. milliseconds_since_card_tapped
        let elapsedTimeSinceCardTapped = calculateElapsedTimeInMilliseconds(start: cardReaderTapped,
                                                                            end: Date().timeIntervalSince1970)

        ServiceLocator.analytics.track(event: .PointOfSale.cardPresentCollectPaymentSuccess(
            millisecondsSinceCustomerIteractionStarted: elapsedTimeSinceCustomerInteraction,
            millisecondsSinceOrderCreationSuccess: elapsedTimeSinceOrderCreation,
            millisecondsSinceReaderReadyToCollect: elapsedTimeSinceCardReaderReady,
            millisecondsSinceCardTapped: elapsedTimeSinceCardTapped
        )
        )
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
        orderCreated = Date().timeIntervalSince1970
    }

    func trackCardReaderReady() {
        cardReaderReady = Date().timeIntervalSince1970
    }

    func trackCardReaderTapped() {
        cardReaderTapped = Date().timeIntervalSince1970
    }

    private func calculateElapsedTimeInMilliseconds(start: Double, end: Double) -> Double {
        floor((end - start) * 1000)
    }
}

// Protocol conformance. These events are not needed for IPP, only for POS.
extension CollectOrderPaymentAnalytics {
    func trackCustomerInteractionStarted() { }
}
