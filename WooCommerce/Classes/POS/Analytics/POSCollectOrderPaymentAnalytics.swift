import Yosemite

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    private var customerInteractionStarted: Double = 0

    func preflightResultReceived(_ result: CardReaderPreflightResult?) { }
    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) { }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        let elapsedTime = calculateElapsedTimeInMilliseconds(start: customerInteractionStarted, end: Date().timeIntervalSince1970)
        ServiceLocator.analytics.track(event:
                .PointOfSale.cardPresentCollectPaymentSuccess(millisecondsSinceCustomerIteractionStated: elapsedTime))
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

    private func calculateElapsedTimeInMilliseconds(start: Double, end: Double) -> Double {
        floor((end - start) * 1000)
    }
}

// Protocol conformance. These events are not needed for IPP, only for POS.
extension CollectOrderPaymentAnalytics {
    func trackCustomerInteractionStarted() { }
}
