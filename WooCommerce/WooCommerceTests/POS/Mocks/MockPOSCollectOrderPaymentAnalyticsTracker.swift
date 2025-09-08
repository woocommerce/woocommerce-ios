@testable import WooCommerce
import struct Yosemite.PaymentIntent

final class MockPOSCollectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking {
    var didCallTrackCheckoutTapped = false

    func trackCustomerInteractionStarted() {
        // no-op
    }

    func trackOrderSyncSuccess() {
        // no-op
    }

    func trackCardReaderReady() {
        // no-op
    }

    func trackCardReaderTapped() {
        // no-op
    }

    func trackCheckoutTapped() {
        didCallTrackCheckoutTapped = true
    }

    func resetCheckoutTapCountTracker() {
        // no-op
    }

    var didCallTrackSuccessfulCashPayment = false
    func trackSuccessfulCashPayment() {
        didCallTrackSuccessfulCashPayment = true
    }

    var connectedReaderModel: String?

    func preflightResultReceived(_ result: WooCommerce.CardReaderPreflightResult?) {
        // no-op
    }

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) {
        // no-op
    }

    func trackSuccessfulCardPayment(capturedPaymentData: WooCommerce.CardPresentCapturedPaymentData) {
        // no-op
    }

    func trackPaymentFailure(with error: any Error) {
        // no-op
    }

    func trackPaymentCancelation(cancelationSource: WooCommerce.WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        // no-op
    }

    func trackEmailTapped() {
        // no-op
    }

    func trackReceiptPrintTapped() {
        // no-op
    }

    func trackReceiptPrintSuccess() {
        // no-op
    }

    func trackReceiptPrintCanceled() {
        // no-op
    }

    func trackReceiptPrintFailed(error: any Error) {
        // no-op
    }
}
