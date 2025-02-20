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
    func trackSuccessfulCardPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
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
}


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
    
    func trackSuccessfulCashPayment() {
        // no-op
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
