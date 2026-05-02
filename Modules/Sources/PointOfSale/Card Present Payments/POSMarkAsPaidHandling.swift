import struct Yosemite.Order

/// Handles the "mark order as paid" step for orders that were collected
/// out-of-band (external reader, account credit, gift card, etc.).
protocol POSMarkAsPaidHandling {
    func markOrderAsPaid(for order: Order) async throws
}
