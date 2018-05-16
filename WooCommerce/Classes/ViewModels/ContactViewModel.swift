import Foundation
import UIKit
import Gridicons
import Contacts

enum ContactType {
    case billing
    case shipping
}

class ContactViewModel {
    let title: String
    let fullName: String
    let formattedAddress: String?
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
        formattedAddress = contact.postalAddresses.first?.value.formatted(as: .mailingAddress) ?? ""
        email = contact.emailAddresses.first?.value as String?
    }

    struct Constants {
        static let rowHeight = CGFloat(38)
        static let iconFrame = CGRect(x: 8, y: 0, width: 44, height: 44)
        static let accessoryFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
    }
}
