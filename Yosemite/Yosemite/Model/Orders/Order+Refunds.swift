import Networking

public extension Order {
    /// Sums up the `OrderRefundCondensed.total` inside `self.refunds`. This is returned as a
    /// **negative** number because that's how the API returns them as.
    ///
    func totalRefunded(using currencyFormatter: CurrencyFormatter) -> NSDecimalNumber {
        refunds.reduce(NSDecimalNumber(decimal: .zero)) { result, refundCondensed -> NSDecimalNumber in
            let totalAsDecimal = currencyFormatter.convertToDecimal(from: refundCondensed.total) ?? .zero
            return result.adding(totalAsDecimal)
        }
    }
}
