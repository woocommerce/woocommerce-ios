import Foundation
import Yosemite

struct RefundFeesCalculationUseCase {
    let fees: [OrderFeeLine]

    let currencyFormatter: CurrencyFormatter

    func calculateRefundValues() -> RefundValues {
        let totalTaxes = fees.compactMap {
            currencyFormatter.convertToDecimal(from: $0.totalTax) as Decimal?
        }.reduce(0, +)

        let subtotal = fees.compactMap {
            currencyFormatter.convertToDecimal(from: $0.total) as Decimal?
        }.reduce(0, +)

        return RefundValues(subtotal: subtotal, tax: totalTaxes)
    }
}

// MARK: Helper types
extension RefundFeesCalculationUseCase {
    /// Tuple to return calculations results
    ///
    struct RefundValues {
        let subtotal: Decimal
        let tax: Decimal
        var total: Decimal {
            return subtotal + tax
        }
    }
}
