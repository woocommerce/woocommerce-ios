import Foundation
import Contacts
import Yosemite


// Yosemite.Address Helper Methods
//
extension Address {

    /// Returns the First + LastName combined.
    ///
    var fullName: String {
        return firstName + " " + lastName
    }

    /// returns the Postal Address, formated and ready for display.
    ///
    var formattedPostalAddress: String {
        return postalAddress.formatted(as: .mailingAddress)
    }
}


// MARK: - Private Methods
//
private extension Address {

    /// Returns the two Address Lines combined (if there are, effectively, two lines).
    /// Per US Post Office standardized rules for address lines. Ref. https://pe.usps.com/text/pub28/28c2_001.htm
    ///
    var combinedAddress: String {
        guard let address2 = address2, address2.isEmpty == false else {
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

        return address
    }
}
