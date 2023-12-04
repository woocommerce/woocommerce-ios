import Foundation
import Yosemite
import WooFoundation

/// Represents fees details for an order to be refunded. Meant to be rendered by `RefundFeesDetailsTableViewCell`
///
struct RefundCustomAmountsDetailsViewModel {
    let feesTaxes: String
    let feesSubtotal: String
    let feesTotal: String
}

// MARK: Convenience Initializers
extension RefundCustomAmountsDetailsViewModel {
    /// Creates a `RefundCustomAmountsDetailsViewModel` based on a `[OrderFeeLine]`
    ///
    init(fees: [OrderFeeLine], currency: String, currencySettings: CurrencySettings) {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        let feeRefundValues = RefundFeesCalculationUseCase(fees: fees, currencyFormatter: currencyFormatter).calculateRefundValues()

        self.feesTaxes = currencyFormatter.formatAmount(feeRefundValues.tax, with: currency) ?? ""
        self.feesSubtotal = currencyFormatter.formatAmount(feeRefundValues.subtotal, with: currency) ?? ""
        self.feesTotal = currencyFormatter.formatAmount(feeRefundValues.total, with: currency) ?? ""
    }
}
