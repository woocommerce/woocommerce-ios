@testable import PointOfSale
import struct Yosemite.PaymentIntent
import struct Yosemite.Order

final class MockPOSCollectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking {
    var didCallTrackCheckoutTapped = false

    var cardPaymentOrder: Order?
    func prepareForCardPayment(order: Order) {
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

    var cashPaymentOrder: Order?
    var didCallTrackSuccessfulCashPayment = false
    func trackSuccessfulCashPayment(order: Yosemite.Order) {
        cashPaymentOrder = order
        didCallTrackSuccessfulCashPayment = true
    }

    var markAsPaidPaymentOrder: Order?
    var didCallTrackSuccessfulMarkAsPaidPayment = false
    func trackSuccessfulMarkAsPaidPayment(order: Yosemite.Order) {
        markAsPaidPaymentOrder = order
        didCallTrackSuccessfulMarkAsPaidPayment = true
    }

    var scanToPayOrders: [Order] = []
    var didCallTrackSuccessfulScanToPayPayment = false
    func trackSuccessfulScanToPayPayment(order: Yosemite.Order) {
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
