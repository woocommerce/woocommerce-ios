import Foundation
import Yosemite


// MARK: - Order Helper Methods
//
extension Order {

    /// Returns the Currency Symbol associated with the current order.
    ///
    var currencySymbol: String {
        let components = [NSLocale.Key.currencyCode.rawValue: currency]
        let identifier = NSLocale.localeIdentifier(fromComponents: components)

        return NSLocale(localeIdentifier: identifier).currencySymbol
    }

    /// FIXME: Creates an empty-string value Billing details, until i6 fix
    ///
    func generateEmptyBillingAddress() -> Address {
        return Address(firstName: "", lastName: "", company: "", address1: "", address2: "", city: "", state: "", postcode: "", country: "", phone: "", email: "")
    }
}
