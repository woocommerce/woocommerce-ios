import struct Yosemite.Order
import protocol Yosemite.POSOrderServiceProtocol

/// Handles cash payment completion for bookings by marking the order as paid via the order service.
struct POSBookingCashPaymentHandler: POSCashPaymentHandling {
    let orderService: POSOrderServiceProtocol

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        try await orderService.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: changeDueAmount)
    }
}
