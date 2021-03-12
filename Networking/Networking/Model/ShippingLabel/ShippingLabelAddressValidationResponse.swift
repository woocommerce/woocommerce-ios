import Foundation

/// Represents Shipping Label Address that has been validated or that generated an error.
///
public struct ShippingLabelAddressValidationResponse: Equatable, GeneratedFakeable {
    public let address: ShippingLabelAddress?
    public let errors: ShippingLabelAddressValidationError?

    /// When sending an address to normalize to the server, if the response has the is_trivial_normalization property set to true,
    /// then the normalized address will be automatically accepted without user intervention.
    /// As its name indicates, that flag will be set when the changes made by the address normalizator were trivial,
    /// such as adding the +4 portion to a ZIP code, or changing capitalization, or changing street to st for example.
    ///
    public let isTrivialNormalization: Bool?

    public init(address: ShippingLabelAddress?, errors: ShippingLabelAddressValidationError?, isTrivialNormalization: Bool?) {
        self.address = address
        self.errors = errors
        self.isTrivialNormalization = isTrivialNormalization
    }
}

extension ShippingLabelAddressValidationResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decodeIfPresent(ShippingLabelAddress.self, forKey: .address)
        let errors = try container.decodeIfPresent(ShippingLabelAddressValidationError.self, forKey: .errors)
        let isTrivialNormalization = try container.decodeIfPresent(Bool.self, forKey: .isTrivialNormalization)
        self.init(address: address, errors: errors, isTrivialNormalization: isTrivialNormalization)
    }
}

/// Defines all of the ShippingLabelAddressValidationResponse CodingKeys
///
private extension ShippingLabelAddressValidationResponse {
    enum CodingKeys: String, CodingKey {
        case address = "normalized"
        case errors = "field_errors"
        case isTrivialNormalization = "is_trivial_normalization"
    }
}
