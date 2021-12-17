import Foundation
import Yosemite
/// Calculates the Order fee values(subtotal, total and tax) to be refunded.
///
struct RefundFeesCalculationUseCase {

    /// Order Fees and their quantities to be refunded
    ///
    let fees: [OrderFeeLine]

    /// Formatter to convert string values to decimal values
    ///
    let currencyFormatter: CurrencyFormatter

    /// Calculates the Order fee values(subtotal, total and tax) to be refunded.
    ///
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
