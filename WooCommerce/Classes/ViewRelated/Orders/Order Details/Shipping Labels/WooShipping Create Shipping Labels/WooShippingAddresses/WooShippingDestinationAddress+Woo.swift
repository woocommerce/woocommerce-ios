import Foundation
import Contacts
import Yosemite

// Yosemite.WooShippingDestinationAddress Helper Methods
//
extension WooShippingDestinationAddress {
    /// Returns the First + LastName combined according to language rules and Locale.
    ///
    var fullName: String {
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName

        return PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: [])
    }
}
