import Foundation
import Yosemite

/// Calculates the total refunded value of an `Order`.
///
struct TotalRefundedCalculationUseCase {

    private let order: Order
    private let currencyFormatter: CurrencyFormatter
    private let locale: Locale

    init(order: Order, currencyFormatter: CurrencyFormatter, locale: Locale = .current) {
        self.order = order
        self.currencyFormatter = currencyFormatter
        self.locale = locale
    }

    /// Sums up the `OrderRefundCondensed.total` inside `self.order`. This is returned as a
    /// **negative** number because that's how the API returns them as.
    func totalRefunded() -> NSDecimalNumber {
        order.refunds.reduce(NSDecimalNumber.zero) { result, refundCondensed -> NSDecimalNumber in
            let totalAsDecimal = currencyFormatter.convertToDecimal(from: refundCondensed.total, locale: locale) ?? .zero

            /// Even though the API returns refunds as negative, there is one case
            /// where the refund is a positive number: right between issuing the refund
            ///  and having the Order object updated with data from the API.
            let total = totalAsDecimal.isNegative() ? totalAsDecimal : totalAsDecimal.multiplying(by: -1)
            return result.adding(total)
        }
    }
}
