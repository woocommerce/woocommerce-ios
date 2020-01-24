import Foundation
import Contacts
import Yosemite


extension CNContact {
    static func from(address: Address) -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = address.firstName
        contact.familyName = address.lastName

        if let company = address.company, company.isNotEmpty {
            contact.organizationName = company
        }

        let postalAddress = CNMutablePostalAddress()
        // Per US Post Office standardized rules for address lines
        // https://pe.usps.com/text/pub28/28c2_001.htm
        var combinedAddress = address.address1
        if let addressLine2 = address.address2, addressLine2.isNotEmpty {
            combinedAddress += " " + addressLine2
        }
        postalAddress.street = combinedAddress
        postalAddress.city = address.city
        postalAddress.state = address.state
        postalAddress.postalCode = address.postcode

        if let phone = address.phone {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))]
        }

        if let emailAddress = address.email as NSString? {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: emailAddress)]
        }

        contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postalAddress)]

        return contact
    }
}

extension CNPostalAddress {
    func formatted(as style: CNPostalAddressFormatterStyle) -> String? {
        let address = CNPostalAddressFormatter.string(from: self, style: style)
        return address.isEmpty ? nil : address
    }
}
