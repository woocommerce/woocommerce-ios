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

        guard let code = Currency.Code(rawValue: currency) else {
            return String()
        }

        return Currency.symbol(from: code)
    }

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return CurrencyFormatter().formatCurrency(using: total.friendlyString(),
                                                  at: Currency.position,
                                                  with: currencySymbol)
    }
}
