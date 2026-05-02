import struct Yosemite.Order

/// Marks the cart's order as paid manually via the order controller.
struct POSCartMarkAsPaidHandler: POSMarkAsPaidHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func markOrderAsPaid(for order: Order) async throws {
        try await orderController.markOrderAsPaidManually()
    }
}
