import Foundation
import struct Yosemite.Order

/// The order data needed by the payment controller.
struct POSPaymentOrder {
    let order: Order
    let formattedTotal: String
    let totalDecimal: Decimal
    let paymentURL: URL?

    init(order: Order,
         formattedTotal: String,
         totalDecimal: Decimal,
         paymentURL: URL? = nil) {
        self.order = order
        self.formattedTotal = formattedTotal
        self.totalDecimal = totalDecimal
        self.paymentURL = paymentURL
    }
}

/// Provides an Order for the payment model to collect payment against.
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> POSPaymentOrder
}
