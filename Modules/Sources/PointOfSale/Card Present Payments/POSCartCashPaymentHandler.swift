import struct Yosemite.Order

/// Handles cash payment completion for the POS cart flow by delegating to the order controller.
struct POSCartCashPaymentHandler: POSCashPaymentHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        try await orderController.collectCashPayment(changeDueAmount: changeDueAmount)
    }
}
