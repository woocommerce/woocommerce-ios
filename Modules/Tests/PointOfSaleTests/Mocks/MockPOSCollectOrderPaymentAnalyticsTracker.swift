@testable import PointOfSale
import struct Yosemite.PaymentIntent

final class MockPOSCollectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking {
    var didCallTrackCheckoutTapped = false

    var cardPaymentOrder: POSPaymentAnalyticsOrder?
    func prepareForCardPayment(order: POSPaymentAnalyticsOrder) {
        cardPaymentOrder = order
    }

    func trackCustomerInteractionStarted() {
        // no-op
    }

    private(set) var orderSyncSuccessCount = 0
    func trackOrderSyncSuccess() {
        orderSyncSuccessCount += 1
    }

    func trackCardReaderReady() {
        // no-op
    }

    func trackCardReaderTapped() {
        // no-op
    }

    var cardReaderConnectionChanges: [Bool] = []
    func trackCardReaderConnectionChanged(isConnected: Bool) {
        cardReaderConnectionChanges.append(isConnected)
    }

    var cardPaymentAttemptStartedCount = 0
    func trackCardPaymentAttemptStarted() {
        cardPaymentAttemptStartedCount += 1
    }

    private(set) var didResetCheckoutTiming = false
    func resetCheckoutTiming() {
        didResetCheckoutTiming = true
    }

    func trackCheckoutTapped() {
        didCallTrackCheckoutTapped = true
    }

    var cashPaymentOrder: POSPaymentAnalyticsOrder?
    var didCallTrackSuccessfulCashPayment = false
    func trackSuccessfulCashPayment(order: POSPaymentAnalyticsOrder) {
        cashPaymentOrder = order
        didCallTrackSuccessfulCashPayment = true
    }

    var markAsPaidPaymentOrder: POSPaymentAnalyticsOrder?
    var didCallTrackSuccessfulMarkAsPaidPayment = false
    func trackSuccessfulMarkAsPaidPayment(order: POSPaymentAnalyticsOrder) {
        markAsPaidPaymentOrder = order
        didCallTrackSuccessfulMarkAsPaidPayment = true
    }

    var scanToPayOrders: [POSPaymentAnalyticsOrder] = []
    var didCallTrackSuccessfulScanToPayPayment = false
    func trackSuccessfulScanToPayPayment(order: POSPaymentAnalyticsOrder) {
        scanToPayOrders.append(order)
        didCallTrackSuccessfulScanToPayPayment = true
    }

    var connectedReaderModel: String?

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent, recordPaymentConfirmation: Bool) {
        // no-op
    }

    func trackPaymentFailure(with error: any Error) {
        // no-op
    }
}
