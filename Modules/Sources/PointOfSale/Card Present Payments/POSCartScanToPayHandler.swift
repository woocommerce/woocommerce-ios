/// Handles scan-to-pay completion for the POS cart flow by recording the payment method title
/// and adding an audit-trail order note.
/// The actual order status flip happens via the gateway webhook on the WC backend.
struct POSCartScanToPayHandler: POSScanToPayHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeScanToPayPayment() async throws {
        try await orderController.confirmScanToPayPayment()
    }

    func recordScanToPayPaymentMethod() async {
        await orderController.recordScanToPayPaymentMethod()
    }
}
