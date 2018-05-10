import Foundation
import Contacts
import PhoneNumberKit

enum ContactType {
    case billing
    case shipping
}

class ContactViewModel {
    let title: String
    var fullName: String
    var formattedAddress: String
    var cleanedPhoneNumber: String?
    var phoneNumber: String?
    var email: String?

    init(with address: Address, contactType: ContactType) {
        switch contactType {
        case .billing:
            title =  NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        case .shipping:
            title =  NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        }
        let contact = CNContact.from(address: address)
        fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? address.firstName + " " + address.lastName

        if let cnPhoneNumber = contact.phoneNumbers.first {
            phoneNumber = cnPhoneNumber.value.stringValue
        }

        cleanedPhoneNumber = address.phone?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        let cnAddress = contact.postalAddresses.first
        let postalAddress = cnAddress!.value
        formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)

        if let cnEmail = contact.emailAddresses.first {
            email = cnEmail.value as String
        }
    }
}

extension CNContact {
    static func from(address: Address) -> CNContact {
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

        if let emailAddress = address.email as NSString? {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: emailAddress)]
        }

        contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postalAddress)]

        return contact
    }
}
