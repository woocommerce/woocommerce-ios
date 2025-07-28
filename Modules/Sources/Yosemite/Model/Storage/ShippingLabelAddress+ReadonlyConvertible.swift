import Foundation
import Storage

// Storage.ShippingLabelAddress: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelAddress: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelAddress with the a ReadOnly ShippingLabelAddress.
    ///
    public func update(with address: Yosemite.ShippingLabelAddress) {
        company = address.company
        name = address.name
        phone = address.phone
        country = address.country
        state = address.state
        address1 = address.address1
        address2 = address.address2
        city = address.city
        postcode = address.postcode
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelAddress {
        .init(company: company,
              name: name,
              phone: phone,
              country: country,
              state: state,
              address1: address1,
              address2: address2,
              city: city,
              postcode: postcode)
    }
}
