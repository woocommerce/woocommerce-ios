import Foundation

public struct RefundParameters {
    /// The chargeId for the charge which is being refunded
    public let chargeId: String

    /// The amount of the refund.
    public let amount: Decimal

    /// Three-letter ISO currency code, in lowercase. Must be a supported currency.
    @CurrencyCode
    public private(set) var currency: String

    public init(chargeId: String, amount: Decimal, currency: String) {
        self.chargeId = chargeId
        self.amount = amount
        self.currency = currency
    }
}
