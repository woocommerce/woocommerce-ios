public protocol POSCollectOrderPaymentAnalyticsTracking {
    func setPOSLayoutForCurrentPayment(_ posLayout: POSAnalyticsLayout)
    func trackCustomerInteractionStarted()
    func trackOrderSyncSuccess()
    func trackCardReaderReady()
    func trackCardReaderTapped()
    func trackCheckoutTapped()
    func trackSuccessfulCashPayment()
    func trackSuccessfulScanToPayPayment()
    func trackSuccessfulMarkAsPaidPayment()
}
