import struct Yosemite.Order

public protocol POSCollectOrderPaymentAnalyticsTracking {
    func prepareForCardPayment(order: Order)
    func trackCustomerInteractionStarted()
    func trackOrderSyncSuccess()
    func trackCardReaderReady()
    func trackCardReaderTapped()
    func trackCheckoutTapped()
    func trackSuccessfulCashPayment(order: Order)
    func trackSuccessfulScanToPayPayment(order: Order)
    func trackSuccessfulMarkAsPaidPayment(order: Order)
}
