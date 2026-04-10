import Foundation

public struct BookingPaymentInfo: Hashable {
    public let paymentMethodID: String
    public let paymentMethodTitle: String
    public let subtotal: String
    public let subtotalTax: String
    public let total: String
    public let totalTax: String

    public init(paymentMethodID: String,
                paymentMethodTitle: String,
                subtotal: String,
                subtotalTax: String,
                total: String,
                totalTax: String) {
        self.paymentMethodID = paymentMethodID
        self.paymentMethodTitle = paymentMethodTitle
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.total = total
        self.totalTax = totalTax
    }
}
