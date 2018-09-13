import Foundation
import UIKit
import Gridicons
import Contacts
import Yosemite



class ContactViewModel {
    let cleanedPhoneNumber: String?
    let phoneNumber: String?
    let email: String?

    init(with address: Address) {
        let contact = CNContact.from(address: address)
        phoneNumber = contact.phoneNumbers.first?.value.stringValue
        cleanedPhoneNumber = address.phone?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        email = contact.emailAddresses.first?.value as String?
    }
}
