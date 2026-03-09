import Foundation
import struct Yosemite.Order
import protocol Yosemite.POSOrderServiceProtocol

/// Provides an Order for the payment controller by loading it by ID from the remote.
/// Used by the bookings payment flow, where the order already exists on the server.
struct POSBookingPaymentOrderProvider: POSPaymentOrderProviding {
    let orderID: Int64
    let formattedTotal: String
    let orderService: POSOrderServiceProtocol

    func provideOrder() async throws -> POSPaymentOrder {
        let order = try await orderService.loadOrder(orderID: orderID)
        let totalDecimal = Decimal(string: order.total) ?? 0
        return POSPaymentOrder(order: order,
                               formattedTotal: formattedTotal,
                               totalDecimal: totalDecimal)
    }
}
