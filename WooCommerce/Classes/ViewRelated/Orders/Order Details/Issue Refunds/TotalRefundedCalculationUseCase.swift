import Foundation
import Yosemite

/// Calculates the total refunded value of an `Order`.
///
struct TotalRefundedCalculationUseCase {

    private let order: Order
    private let currencyFormatter: CurrencyFormatter

    init(order: Order, currencyFormatter: CurrencyFormatter) {
        self.order = order
        self.currencyFormatter = currencyFormatter
    }

    /// Sums up the `OrderRefundCondensed.total` inside `self.order`. This is returned as a
    /// **negative** number because that's how the API returns them as.
    func totalRefunded() -> NSDecimalNumber {
        order.refunds.reduce(NSDecimalNumber(decimal: .zero)) { result, refundCondensed -> NSDecimalNumber in
            let totalAsDecimal = currencyFormatter.convertToDecimal(from: refundCondensed.total) ?? .zero
            return result.adding(totalAsDecimal)
        }
    }
}
