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

    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) {
        // no-op
    }

    func trackPaymentFailure(with error: any Error) {
        // no-op
    }
}
