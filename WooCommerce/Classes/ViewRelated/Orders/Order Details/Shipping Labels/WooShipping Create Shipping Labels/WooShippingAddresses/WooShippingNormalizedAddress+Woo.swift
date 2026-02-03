import Foundation
import Contacts
import Yosemite

// Yosemite.WooShippingNormalizedAddress Helper Methods
//
extension WooShippingNormalizedAddress {

    /// Returns the First + LastName combined according to language rules and Locale.
    ///
    var fullName: String {
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName

        return PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: [])
    }

    /// Converts the normalized address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use in e.g. fetching available shipping rates or purchasing the label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        WooShippingAddress(company: company,
                           name: fullName,
                           email: email,
                           phone: phone,
                           country: country,
                           state: state,
                           address1: address1,
                           address2: address2,
                           city: city,
                           postcode: postcode)
    }
}
