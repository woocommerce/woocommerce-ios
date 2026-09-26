import struct Yosemite.Order

public protocol POSCollectOrderPaymentAnalyticsTracking {
    func prepareForCardPayment(order: POSPaymentAnalyticsOrder)
    func trackCustomerInteractionStarted()
    func trackOrderSyncSuccess()
    func trackCardReaderReady()
    func trackCardReaderTapped()
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
