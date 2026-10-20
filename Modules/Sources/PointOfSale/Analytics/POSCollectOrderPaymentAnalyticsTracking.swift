import struct Yosemite.Order

public protocol POSCollectOrderPaymentAnalyticsTracking {
    func prepareForCardPayment(order: POSPaymentAnalyticsOrder)
    func trackCustomerInteractionStarted()
    func trackOrderSyncSuccess()
    func trackCardReaderReady()
    func trackCardReaderTapped()
    /// Called on every reader connection status update, so the tracker knows whether a reader is connected
    /// when a customer interaction starts, and when one connects afterwards.
    func trackCardReaderConnectionChanged(isConnected: Bool)
    /// Called when a card payment attempt starts validating the order or preparing the reader, including retries.
    /// Re-arms the reader-ready stamp even if the previous attempt ended without an outcome event.
    func trackCardPaymentAttemptStarted()
    func trackCheckoutTapped()
    func trackSuccessfulCashPayment(order: POSPaymentAnalyticsOrder)
    func trackSuccessfulScanToPayPayment(order: POSPaymentAnalyticsOrder)
    func trackSuccessfulMarkAsPaidPayment(order: POSPaymentAnalyticsOrder)
}

public struct POSPaymentAnalyticsOrder: Equatable {
    public let orderID: Int64
    public let currency: String
    public let total: String
    public let paymentMethodID: String

    public init(orderID: Int64, currency: String, total: String, paymentMethodID: String) {
        self.orderID = orderID
        self.currency = currency
        self.total = total
        self.paymentMethodID = paymentMethodID
    }

    init(order: Order) {
        self.init(orderID: order.orderID, currency: order.currency, total: order.total, paymentMethodID: order.paymentMethodID)
    }
}
