import Foundation
import Yosemite

/// Calculates the total refunded value of an `Order`.
///
struct TotalRefundedCalculationUseCase {

    private let currencyFormatter: CurrencyFormatter
    private let order: Order

    init(order: Order, currencySettings: CurrencySettings) {
        self.order = order
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Returns the total refunded of `self.order`.
    func totalRefunded() -> NSDecimalNumber {
        order.refunds.reduce(NSDecimalNumber(decimal: .zero)) { result, refundCondensed -> NSDecimalNumber in
            let totalAsDecimal = currencyFormatter.convertToDecimal(from: refundCondensed.total) ?? .zero
            return result.adding(totalAsDecimal)
        }
    }
}
