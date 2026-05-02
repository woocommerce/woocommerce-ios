import struct Yosemite.Order

/// Marks the cart's order as paid manually via the order controller. Used for the cart flow;
/// other flows (e.g. bookings) can provide their own implementation when wiring the feature there.
struct POSCartMarkAsPaidHandler: POSMarkAsPaidHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func markOrderAsPaid(for order: Order) async throws {
        try await orderController.markOrderAsPaidManually()
    }
}
