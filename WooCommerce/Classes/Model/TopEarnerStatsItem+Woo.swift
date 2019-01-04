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

        guard let code = CurrencySettings.CurrencyCode(rawValue: currency) else {
            return String()
        }

        return CurrencySettings().symbol(from: code)
    }

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return CurrencyFormatter().formatCurrency(using: total.friendlyString(),
                                                  at: CurrencySettings.shared.currencyPosition,
                                                  with: currencySymbol)
    }
}
