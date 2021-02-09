import Foundation

/// Represents Shipping Label Address that has been validated or that generated an error.
///
public struct ShippingLabelAddressValidationResponse: Equatable {
    public let address: ShippingLabelAddress?
    public let errors: ShippingLabelAddressValidationError?

    public init(address: ShippingLabelAddress?, errors: ShippingLabelAddressValidationError?) {
        self.address = address
        self.errors = errors
    }
}

extension ShippingLabelAddressValidationResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decodeIfPresent(ShippingLabelAddress.self, forKey: .address)
        let errors = try container.decodeIfPresent(ShippingLabelAddressValidationError.self, forKey: .errors)
        self.init(address: address, errors: errors)
    }
}

/// Defines all of the ShippingLabelAddressValidationResponse CodingKeys
///
private extension ShippingLabelAddressValidationResponse {
    enum CodingKeys: String, CodingKey {
        case address = "normalized"
        case errors = "field_errors"
    }
}
