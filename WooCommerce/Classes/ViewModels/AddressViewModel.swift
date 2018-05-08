import Foundation
import Contacts

enum ContactType {
    case billing
    case shipping
}

class ContactViewModel {
    let title: String
    let fullName: String
    var formattedAddress: String
    let phoneNumber: String
    let email: String

    init(with address: Address, contactType: ContactType) {
        switch contactType {
        case .billing:
            title =  NSLocalizedString("Billing details", comment: "Shipping title for customer info cell")
        case .shipping:
            title =  NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        }
        let contact = createContact(address)
        fullName = CNContactFormatter.string(from: contact, style: .fullName)!
        phoneNumber = contact.phoneNumbers[0].value.stringValue
        email = contact.emailAddresses[0].value as String
        let postalAddress = contact.postalAddresses[0].value
        formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
    }

    func createContact(_ address: Address) -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = address.firstName
        contact.familyName = address.lastName

        if let organization = address.company  {
            if organization.isEmpty == false {
                contact.organizationName = organization
            }
        }

        let postalAddress = CNMutablePostalAddress()
        // Per US Post Office standardized rules for address lines
        // https://pe.usps.com/text/pub28/28c2_001.htm
        var combinedAddress: String
        if let addressLine2 = address.address2 {
            if addressLine2.isEmpty == false {
                combinedAddress = String(format: "%@ %@", [address.address1, addressLine2])
            } else {
                combinedAddress = address.address1
            }
        } else {
            combinedAddress = address.address1
        }
        postalAddress.street = combinedAddress
        postalAddress.city = address.city
        postalAddress.state = address.state
        postalAddress.postalCode = address.postcode

        if let phone = address.phone {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))]
        }

        if let emailAddress = email as NSString? {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: emailAddress)]
        }

        contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postalAddress)]

        return contact
    }
}
