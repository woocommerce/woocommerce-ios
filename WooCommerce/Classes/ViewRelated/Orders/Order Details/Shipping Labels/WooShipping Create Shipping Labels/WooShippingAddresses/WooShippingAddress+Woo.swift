import Foundation
import Contacts
import Yosemite

// Yosemite.WooShippingAddress Helper Methods
//
extension WooShippingAddress {

    /// Returns the two Address Lines combined (if there are, effectively, two lines).
    /// Per US Post Office standardized rules for address lines. Ref. https://pe.usps.com/text/pub28/28c2_001.htm
    ///
    var combinedAddress: String {
        guard address2.isNotEmpty else {
            return address1
        }

        return address1 + " " + address2
    }

    /// Returns the Postal Address, formatted and ready for display.
    ///
    var formattedPostalAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)?.replacingOccurrences(of: "\n", with: ", ")
    }

    /// Digits-only representation of the phone number.
    var phoneDigits: String {
        WooShippingPhoneValidator.digits(from: phone)
    }

    /// Whether the phone number is valid for label purchase.
    /// For US addresses, the phone must be 10 digits (or 11 with leading "1").
    var hasValidPhoneNumberForShipping: Bool {
        WooShippingPhoneValidator.isValid(phone: phone,
                                          country: country)
    }
}

private extension WooShippingAddress {

    /// Returns a CNPostalAddress with the receiver's properties
    ///
    var postalAddress: CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = combinedAddress
        address.city = city
        address.state = state
        address.postalCode = postcode
        address.country = country
        address.isoCountryCode = country

        return address
    }
}
