import Foundation
import Yosemite
import WooFoundation
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
        let totalTaxes = fees.map(taxToRefund(from:)).reduce(0, +)

        let subtotal = fees.compactMap {
            currencyFormatter.convertToDecimal($0.total) as Decimal?
        }.reduce(0, +)

        return RefundValues(subtotal: subtotal, tax: totalTaxes)
    }

    /// Sums the fee's tax lines rather than using `totalTax`: when the store rounds tax per line
    /// (the WooCommerce default), `totalTax` is rounded to currency decimals while `total` and
    /// `taxes[].total` keep the API's full precision, so mixing them can push the refund amount
    /// above the order total and the API rejects the refund with "Invalid refund amount".
    ///
    private func taxToRefund(from fee: OrderFeeLine) -> Decimal {
        guard fee.taxes.isNotEmpty else {
            return currencyFormatter.convertToDecimal(fee.totalTax) as Decimal? ?? .zero
        }
        return fee.taxes.reduce(Decimal.zero) { total, taxLine in
            total + ((currencyFormatter.convertToDecimal(taxLine.total) as Decimal?) ?? .zero)
        }
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
