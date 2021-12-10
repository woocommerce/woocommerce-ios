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
        self.feesTaxes = ""
        self.feesSubtotal = ""
        self.feesTotal = ""
    }
}
