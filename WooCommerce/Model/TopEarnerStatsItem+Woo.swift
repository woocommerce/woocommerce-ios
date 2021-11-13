import Foundation
import Yosemite


// MARK: - TopEarnerStatsItem Helper Methods
//
extension TopEarnerStatsItem {

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatHumanReadableAmount(String(total), with: currency) ?? String()
    }
}
