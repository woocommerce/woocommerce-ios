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

    /// Returns an order ready for scan-to-pay. For POS this promotes the autoDraft to
    /// `.pending` so the WC backend populates `paymentURL` (the same status the
    /// order-creation flow uses by default).
    func provideOrderForScanToPay() async throws -> POSPaymentOrder
}

extension POSPaymentOrderProviding {
    /// Default falls back to the regular provider — useful for mocks/tests that don't
    /// differentiate between regular and scan-to-pay order acquisition.
    func provideOrderForScanToPay() async throws -> POSPaymentOrder {
        try await provideOrder()
    }
}
