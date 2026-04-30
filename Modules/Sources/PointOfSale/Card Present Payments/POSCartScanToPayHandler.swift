import struct Yosemite.Order

/// Handles scan-to-pay completion for the POS cart flow by delegating to the order controller.
struct POSCartScanToPayHandler: POSScanToPayHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeScanToPayPayment(for order: Order) async throws {
        try await orderController.confirmScanToPayPayment()
    }
}
