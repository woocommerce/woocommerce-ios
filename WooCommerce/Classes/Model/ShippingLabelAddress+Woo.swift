import Foundation
import Contacts
import Yosemite


// Yosemite.ShippingLabelAddress Helper Methods
//
extension ShippingLabelAddress {

    /// Returns the `name`, `company`, and `address`. Basically this var combines the
    /// various components of a ShippingLabelAddress.
    ///
    var fullNameWithCompanyAndAddress: String {
        var output: [String] = [fullNameWithCompany]

        if let formattedPostalAddress = formattedPostalAddress, formattedPostalAddress.isNotEmpty {
            output.append(formattedPostalAddress)
        }

        return output.joined(separator: "\n")
    }

    /// Returns the Postal Address, formated and ready for display.
    ///
    var formattedPostalAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)
    }
}

private extension ShippingLabelAddress {

    /// Returns the `name` and `company` (on a new line). If either the `name` or `company` is empty,
    /// then a single line is returned containing the other value.
    ///
    var fullNameWithCompany: String {
        var output: [String] = []

        if name.isNotEmpty {
            output.append(name)
        }
        if company.isNotEmpty {
            output.append(company)
        }

        return output.joined(separator: "\n")
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
