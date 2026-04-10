import Foundation
import Yosemite

/// Generates mock `ShippingLabelAddress`
///
public struct MockShippingLabelAddress {
    public static func sampleAddress(company: String = "",
                                     name: String = "",
                                     phone: String = "",
                                     country: String = "",
                                     state: String = "",
                                     address1: String = "",
                                     address2: String = "",
                                     city: String = "",
                                     postcode: String = "") -> ShippingLabelAddress {
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
