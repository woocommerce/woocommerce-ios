import Foundation
import Yosemite

// MARK: - OrderStats Helper Methods
//
extension OrderStats {

    /// Returns the currency code associated with the current order stats.
    ///
    var currencyCode: String {
        guard let currencyCode = items?.filter({ !$0.currency.isEmpty }).first?.currency else {
            return String()
        }

        return currencyCode
    }
}
