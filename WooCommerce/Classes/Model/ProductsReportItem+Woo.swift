import Foundation
import Yosemite
import WooFoundation


// MARK: - ProductsReportItem Helper Methods
//
extension ProductsReportItem {

    /// Returns the total string including the currency symbol.
    ///
    var totalString: String {
        CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(total.description) ?? total.description
    }
}
