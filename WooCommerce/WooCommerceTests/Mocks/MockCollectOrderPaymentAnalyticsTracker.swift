import Foundation
@testable import WooCommerce
import Yosemite

final class MockCollectOrderPaymentAnalyticsTracker: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {
        // no-op
    }

    func trackProcessingCompletion(intent: PaymentIntent) {
        // no-op
    }

    var didCallTrackSuccessfulPayment = false
    var spyTrackSuccessfulPaymentCapturedPaymentData: CardPresentCapturedPaymentData? = nil
    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        didCallTrackSuccessfulPayment = true
        spyTrackSuccessfulPaymentCapturedPaymentData = capturedPaymentData
    }

    var didCallTrackPaymentFailure = false
    var spyTrackPaymentFailureError: Error? = nil
    func trackPaymentFailure(with error: Error) {
        didCallTrackPaymentFailure = true
        spyTrackPaymentFailureError = error
    }

    var didCallTrackPaymentCancelation = false
    var spyPaymentCancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource? = nil
    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        didCallTrackPaymentCancelation = true
        spyPaymentCancelationSource = cancelationSource
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

    func trackReceiptPrintFailed(error: Error) {
        // no-op
    }

    func trackCustomerInteractionStarted() {
        // no-op
    }

    func trackOrderCreationSuccess() {
        // no-op
    }

    func trackCardReaderReady() {
        // no-op
    }

    func trackCardReaderTapped() {
        // no-op
    }

    func trackCheckoutTapped() {
        // no-op
    }

    func resetCheckoutTapCountTracker() {
        // no-op
    }
}
