import Foundation
import Storage

// Storage.WooShippingOriginAddress: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingOriginAddress: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelAddress with the a ReadOnly ShippingLabelAddress.
    ///
    public func update(with address: Yosemite.WooShippingOriginAddress) {
        siteID = address.siteID
        id = address.id
        company = address.company
        firstName = address.firstName
        lastName = address.lastName
        phone = address.phone
        country = address.country
        state = address.state
        address1 = address.address1
        address2 = address.address2
        city = address.city
        postcode = address.postcode
        email = address.email
        defaultAddress = address.defaultAddress
        isVerified = address.isVerified
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingOriginAddress {
        .init(siteID: siteID,
              id: id,
              company: company,
              address1: address1,
              address2: address2,
              city: city,
              state: state,
              postcode: postcode,
              country: country,
              phone: phone,
              firstName: firstName,
              lastName: lastName,
              email: email,
              defaultAddress: defaultAddress,
              isVerified: isVerified)
    }
}
