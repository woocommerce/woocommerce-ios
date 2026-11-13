import Foundation
import Yosemite
import WooFoundation

/// Calculates the total value(cost + tax) to be refunded from a shipping line.
///
struct RefundShippingCalculationUseCase {

    /// Shipping line to be refunded
    ///
    let shippingLine: ShippingLine

    /// Formatter to convert string values to decimal values
    ///
    let currencyFormatter: CurrencyFormatter

    /// Calculates the total value(cost + tax) to be refunded.
    ///
    func calculateRefundValue() -> Decimal {
        guard let cost = currencyFormatter.convertToDecimal(shippingLine.total) as Decimal? else {
            return .zero
        }
        return cost + taxToRefund
    }

    /// Sums the shipping line's tax lines rather than using `totalTax`: when the store rounds tax per line
    /// (the WooCommerce default), `totalTax` is rounded to currency decimals while `total` and
    /// `taxes[].total` keep the API's full precision, so mixing them can push the refund amount
    /// above the order total and the API rejects the refund with "Invalid refund amount".
    ///
    private var taxToRefund: Decimal {
        guard shippingLine.taxes.isNotEmpty else {
            return currencyFormatter.convertToDecimal(shippingLine.totalTax) as Decimal? ?? .zero
        }
        return shippingLine.taxes.reduce(Decimal.zero) { total, taxLine in
            total + ((currencyFormatter.convertToDecimal(taxLine.total) as Decimal?) ?? .zero)
        }
    }
}
