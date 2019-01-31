import Foundation
import Yosemite


// MARK: - TopEarnerStatsItem Helper Methods
//
extension TopEarnerStatsItem {

    /// Returns a friendly-formatted total string including the currency symbol
    ///
    var formattedTotalString: String {
        return CurrencyFormatter().formatHumanReadableAmount(String(total), with: currency, roundSmallNumbers: false) ?? String()
    }
}
