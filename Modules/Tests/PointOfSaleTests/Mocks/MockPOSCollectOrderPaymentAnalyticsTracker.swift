@testable import PointOfSale
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

    var didCallTrackSuccessfulCashPayment = false
    func trackSuccessfulCashPayment() {
        didCallTrackSuccessfulCashPayment = true
    }

    var didCallTrackSuccessfulMarkAsPaidPayment = false
    func trackSuccessfulMarkAsPaidPayment() {
        didCallTrackSuccessfulMarkAsPaidPayment = true
    }

    var didCallTrackSuccessfulScanToPayPayment = false
    func trackSuccessfulScanToPayPayment() {
        didCallTrackSuccessfulScanToPayPayment = true
    }

    var connectedReaderModel: String?

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) {
        // no-op
    }

    func trackPaymentFailure(with error: any Error) {
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
