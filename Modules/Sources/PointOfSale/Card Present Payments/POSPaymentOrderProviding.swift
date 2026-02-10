import Foundation
import struct Yosemite.Order

/// The order data needed by the payment controller.
struct POSPaymentOrder {
    let order: Order
    let formattedTotal: String
    let totalDecimal: Decimal
}

/// Provides an Order for the payment controller to collect payment against.
/// Cart flow returns the already-synced order; bookings flow fetches by order ID.
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> POSPaymentOrder
}
