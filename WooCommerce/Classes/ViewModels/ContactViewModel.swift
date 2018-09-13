import Foundation
import UIKit
import Gridicons
import Contacts
import Yosemite



class ContactViewModel {
    let fullName: String
    let formattedAddress: String?
    let cleanedPhoneNumber: String?
    let phoneNumber: String?
    let email: String?

    init(with address: Address) {
        let contact = CNContact.from(address: address)
        fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? address.firstName + " " + address.lastName
        phoneNumber = contact.phoneNumbers.first?.value.stringValue
        cleanedPhoneNumber = address.phone?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        formattedAddress = contact.postalAddresses.first?.value.formatted(as: .mailingAddress) ?? ""
        email = contact.emailAddresses.first?.value as String?
    }
}
