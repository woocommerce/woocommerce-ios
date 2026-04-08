import struct Yosemite.Order

/// Handles the "mark order as paid with cash" step during cash payment.
protocol POSCashPaymentHandling {
    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws
}
