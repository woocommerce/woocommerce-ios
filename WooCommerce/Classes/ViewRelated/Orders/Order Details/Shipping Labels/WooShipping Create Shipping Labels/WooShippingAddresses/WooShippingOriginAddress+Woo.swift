import Foundation
import Contacts
import Yosemite


// Yosemite.WooShippingOriginAddress Helper Methods
//
extension WooShippingOriginAddress {

    /// Returns the `name` and `company` (on a new line). If either the `name` or `company` is empty,
    /// then a single line is returned containing the other value.
    ///
    var fullNameWithCompany: String {
        var output: [String] = []

        if let fullName {
            output.append(fullName)
        }
        if company.isNotEmpty {
            output.append(company)
        }

        return output.joined(separator: "\n")
    }

    /// Returns the Postal Address, formated and ready for display.
    ///
    var formattedPostalAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)?.replacingOccurrences(of: "\n", with: ", ")
    }
}

private extension WooShippingOriginAddress {

    /// Returns the first and last name combined (if there are, effectively, two names).
    /// If only one name is present, that name is returned.
    var fullName: String? {
        switch (firstName.isNotEmpty, lastName.isNotEmpty) {
        case (true, true):
            return "\(firstName) \(lastName)"
        case (true, false):
            return firstName
        case (false, true):
            return lastName
        case (false, false):
            return nil
        }
    }

    /// Returns the two Address Lines combined (if there are, effectively, two lines).
    /// Per US Post Office standardized rules for address lines. Ref. https://pe.usps.com/text/pub28/28c2_001.htm
    ///
    var combinedAddress: String {
        guard address2.isNotEmpty else {
            return address1
        }

        return address1 + " " + address2
    }

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
