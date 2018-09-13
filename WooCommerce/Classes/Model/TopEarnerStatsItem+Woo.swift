import Foundation
import Yosemite


// MARK: - TopEarnerStatsItem Helper Methods
//
extension TopEarnerStatsItem {

    /// Returns the Currency Symbol associated with the current TopEarnerStatsItem.
    ///
    var currencySymbol: String {
        guard !currency.isEmpty else {
            return ""
        }
        guard let identifier = Locale.availableIdentifiers.first(where: { Locale(identifier: $0).currencyCode == currency }) else {
            return currency
        }

        return Locale(identifier: identifier).currencySymbol ?? currency
    }

    /// Returns the a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return currencySymbol + total.friendlyString()
    }
}
