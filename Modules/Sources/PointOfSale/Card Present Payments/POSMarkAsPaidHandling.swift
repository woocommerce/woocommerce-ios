import struct Yosemite.Order

/// Handles the "mark order as paid" step for orders that were collected
/// out-of-band (external reader, account credit, gift card, etc.).
///
/// Mirrors the shape of `POSCashPaymentHandling`. The implementation lives in the cart flow's
/// order controller; tests substitute a mock conforming to this protocol.
protocol POSMarkAsPaidHandling {
    func markOrderAsPaid(for order: Order) async throws
}
