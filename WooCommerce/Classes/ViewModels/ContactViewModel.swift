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
