import Foundation
import Contacts
import Yosemite

extension CNPostalAddress {
    func formatted(as style: CNPostalAddressFormatterStyle) -> String? {
        let address = CNPostalAddressFormatter.string(from: self, style: style)
        return address.isEmpty ? nil : address
    }
}
