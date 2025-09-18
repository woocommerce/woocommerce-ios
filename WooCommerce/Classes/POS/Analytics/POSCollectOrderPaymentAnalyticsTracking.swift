protocol POSCollectOrderPaymentAnalyticsTracking {
    func trackCustomerInteractionStarted()
    func trackOrderSyncSuccess()
    func trackCardReaderReady()
    func trackCardReaderTapped()
    func trackCheckoutTapped()
    func resetCheckoutTapCountTracker()
    func trackSuccessfulCashPayment()
}
