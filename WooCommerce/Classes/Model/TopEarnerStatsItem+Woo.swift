import Foundation
import Yosemite


// MARK: - TopEarnerStatsItem Helper Methods
//
extension TopEarnerStatsItem {

    /// Returns the Currency Symbol associated with the current TopEarnerStatsItem.
    ///
    var currencySymbol: String {
        guard !currency.isEmpty else {
            return String()
        }
        return MoneyFormatter().currencySymbol(currencyCode: currency) ?? String()
    }

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return currencySymbol + total.friendlyString()
    }
}
