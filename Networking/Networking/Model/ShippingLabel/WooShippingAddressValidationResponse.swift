import Foundation

/// Represents Shipping Label Address that has been validated or that generated an error from the WooCommerce Shipping Extension.
///
/// Only used internally for JSON decoding since the response might contain validation errors.
/// For public consumption, we'll convert those to a `WooShippingAddressValidationError`, and expose
/// a `WooShippingAddressValidationSuccess` instead if there were no errors.
///
internal struct WooShippingAddressValidationResponse: Equatable {
    let result: Result<WooShippingAddressValidationSuccess, WooShippingAddressValidationError>

    init(normalizedAddress: WooShippingNormalizedAddress?,
         originalAddress: WooShippingAddress?,
         isTrivialNormalization: Bool?,
         errors: WooShippingAddressValidationError?) {
        if let errors {
            result = .failure(errors)
        } else if let normalizedAddress,
                  let originalAddress,
                  let isTrivialNormalization {
            result = .success(.init(normalizedAddress: normalizedAddress, originalAddress: originalAddress, isTrivialNormalization: isTrivialNormalization))
        } else {
            // This case should never happen, but that's not guaranteed.
            // We'll treat the absence of both the addresses and errors as an error with no message.
            result = .failure(.init(addressError: nil, generalError: nil, nameError: nil))
        }
    }
}

extension WooShippingAddressValidationResponse: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let normalizedAddress = try container.decodeIfPresent(WooShippingNormalizedAddress.self, forKey: .normalized)
        let originalAddress = try container.decodeIfPresent(WooShippingAddress.self, forKey: .original)
        let isTrivialNormalization = try container.decodeIfPresent(Bool.self, forKey: .isTrivialNormalization)
        let errors = try container.decodeIfPresent(WooShippingAddressValidationError.self, forKey: .errors)
        self.init(normalizedAddress: normalizedAddress, originalAddress: originalAddress, isTrivialNormalization: isTrivialNormalization, errors: errors)
    }
}

/// Defines all of the WooShippingAddressValidationResponse CodingKeys
///
private extension WooShippingAddressValidationResponse {
    enum CodingKeys: String, CodingKey {
        case normalized = "normalizedAddress"
        case original = "address"
        case errors = "errors"
        case isTrivialNormalization = "isTrivialNormalization"
    }
}
