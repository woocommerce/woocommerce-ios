import Foundation
import Yosemite


// MARK: - OrderStats Helper Methods
//
extension OrderStats {

    /// Returns the Currency Symbol associated with the current order stats.
    ///
    var currencySymbol: String {
        guard let currency = items?.filter({ !$0.currency.isEmpty}).first?.currency else {
            return ""
        }
        guard let identifier = Locale.availableIdentifiers.first(where: { Locale(identifier: $0).currencyCode == currency }) else
        {
            return currency
        }

        return Locale(identifier: identifier).currencySymbol ?? currency
    }
}
