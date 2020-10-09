import Networking

public extension Order {
    /// Sums up the `OrderRefundCondensed.total` inside `self.refunds`. This is returned as a
    /// **negative** number because that's how the API returns them as.
    ///
    func totalRefunded(using formatter: CurrencyFormatter, locale: Locale = .current) -> NSDecimalNumber {
        refunds.reduce(NSDecimalNumber.zero) { result, refundCondensed -> NSDecimalNumber in
            let totalAsDecimal = formatter.convertToDecimal(from: refundCondensed.total, locale: locale) ?? .zero
            return result.adding(totalAsDecimal)
        }
    }
}
