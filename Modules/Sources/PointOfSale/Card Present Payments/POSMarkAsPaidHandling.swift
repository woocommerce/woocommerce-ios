import struct Yosemite.Order

/// Handles the "mark order as paid" step for orders that were collected
/// out-of-band (external reader, account credit, gift card, etc.).
///
/// Mirrors the shape of `POSCashPaymentHandling`. The implementation lives in the cart flow's
/// order controller; tests substitute a mock conforming to this protocol.
protocol POSMarkAsPaidHandling {
    /// Marks the order as paid manually.
    ///
    /// - Parameters:
    ///   - order: The order to mark as completed.
    ///   - note: Optional merchant-supplied free-form note (e.g. "Bank transfer from Maria").
    ///     When non-empty it is attached to the order as a private order note for
    ///     reconciliation context. Nil/empty preserves existing behaviour.
    func markOrderAsPaid(for order: Order, note: String?) async throws
}
