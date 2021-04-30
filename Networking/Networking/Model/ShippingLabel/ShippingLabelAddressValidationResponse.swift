import Foundation

/// Represents Shipping Label Address that has been validated or that generated an error.
///
/// Only used internally for JSON decoding since the response might contain validation errors.
/// For public consumption, we'll convert those to a `ShippingLabelAddressValidationError`, and expose
/// a `ShippingLabelAddressValidationSuccess` instead if there were no errors.
///
internal struct ShippingLabelAddressValidationResponse: Equatable {
    let result: Result<ShippingLabelAddressValidationSuccess, ShippingLabelAddressValidationError>

    init(address: ShippingLabelAddress?, errors: ShippingLabelAddressValidationError?, isTrivialNormalization: Bool?) {
        if let errors = errors {
            result = .failure(errors)
        } else if let address = address,
                  let isTrivialNormalization = isTrivialNormalization {
            result = .success(.init(address: address, isTrivialNormalization: isTrivialNormalization))
        } else {
            // This case should never happen, but that's not guaranteed.
            // We'll treat the absence of both an address and errors as an error with no message.
            result = .failure(.init(addressError: nil, generalError: nil))
        }
    }
}

extension ShippingLabelAddressValidationResponse: Decodable {
    init(from decoder: Decoder) throws {
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
