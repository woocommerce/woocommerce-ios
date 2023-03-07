import Foundation
import Yosemite
import WooFoundation


// MARK: - TopEarnerStatsItem Helper Methods
//
extension TopEarnerStatsItem {

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatHumanReadableAmount(String(total), with: currency) ?? String()
    }

    /// Returns the  total string including the currency symbol.
    ///
    var totalString: String {
        CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(Decimal(total), with: currency) ?? ""
    }
}
