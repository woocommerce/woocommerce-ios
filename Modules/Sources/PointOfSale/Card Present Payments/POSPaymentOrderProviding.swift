import Foundation
import struct Yosemite.Order

/// The order data needed by the payment controller.
struct POSPaymentOrder {
    let order: Order
    let formattedTotal: String
    let totalDecimal: Decimal
}

/// Provides an Order for the payment model to collect payment against.
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> POSPaymentOrder
}
