import struct Yosemite.Order

/// Handles scan-to-pay completion for the POS cart flow by adding an audit-trail order note.
/// The actual order status flip happens via the gateway webhook on the WC backend.
struct POSCartScanToPayHandler: POSScanToPayHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeScanToPayPayment(for order: Order) async throws {
        try await orderController.confirmScanToPayPayment()
    }
}
