import Foundation
import Yosemite

/// Represents fees details for an order to be refunded. Meant to be rendered by `RefundFeesDetailsTableViewCell`
///
struct RefundFeesDetailsViewModel {
    let feesTaxes: String
    let feesSubtotal: String
    let feesTotal: String
}

// MARK: Convenience Initializers
extension RefundFeesDetailsViewModel {
    /// Creates a `RefundFeesDetailsViewModel` based on a `[OrderFeeLine]`
    ///
    init(fees: [OrderFeeLine], currency: String, currencySettings: CurrencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        let totalTaxes = fees.compactMap {
            currencyFormatter.convertToDecimal(from: $0.totalTax) as Decimal?
        }.reduce(0, +)

        let total = fees.compactMap {
            currencyFormatter.convertToDecimal(from: $0.total) as Decimal?
        }.reduce(0, +)

        self.feesTaxes = "\(totalTaxes)"
        self.feesSubtotal = "\(total - totalTaxes)"
        self.feesTotal = "\(total)"
    }
}
