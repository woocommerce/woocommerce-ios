import Foundation
import Contacts

enum ContactType {
    case billing
    case shipping
}

class ContactViewModel {
    let title: String
    let fullName: String
    let formattedAddress: String
    let cleanedPhoneNumber: String?
    let phoneNumber: String?
    let email: String?

    init(with address: Address, contactType: ContactType) {
        switch contactType {
        case .billing:
            title =  NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        case .shipping:
            title =  NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        }
        let contact = CNContact.from(address: address)
        fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? address.firstName + " " + address.lastName

        phoneNumber = contact.phoneNumbers.first?.value.stringValue

        cleanedPhoneNumber = address.phone?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        let cnAddress = contact.postalAddresses.first
        let postalAddress = cnAddress!.value
        formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)

        email = contact.emailAddresses.first?.value as String?
    }
}
