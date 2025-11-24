import Foundation
import Storage

// MARK: - Storage.BookingCustomerInfo: ReadOnlyConvertible
//
extension Storage.BookingCustomerInfo: ReadOnlyConvertible {
    public func update(with customerInfo: Yosemite.BookingCustomerInfo) {
        billingAddress1 = customerInfo.billingAddress.address1
        billingAddress2 = customerInfo.billingAddress.address2
        billingCity = customerInfo.billingAddress.city
        billingCompany = customerInfo.billingAddress.company
        billingCountry = customerInfo.billingAddress.country
        billingEmail = customerInfo.billingAddress.email
        billingFirstName = customerInfo.billingAddress.firstName
        billingLastName = customerInfo.billingAddress.lastName
        billingPhone = customerInfo.billingAddress.phone
        billingPostcode = customerInfo.billingAddress.postcode
        billingState = customerInfo.billingAddress.state
        note = customerInfo.note
    }

    public func toReadOnly() -> Yosemite.BookingCustomerInfo {
        let address = Yosemite.Address(firstName: billingFirstName ?? "",
                                       lastName: billingLastName ?? "",
                                       company: billingCompany,
                                       address1: billingAddress1 ?? "",
                                       address2: billingAddress2,
                                       city: billingCity ?? "",
                                       state: billingState ?? "",
                                       postcode: billingPostcode ?? "",
                                       country: billingCountry ?? "",
                                       phone: billingPhone,
                                       email: billingEmail)
        return .init(billingAddress: address, note: note)
    }
}
