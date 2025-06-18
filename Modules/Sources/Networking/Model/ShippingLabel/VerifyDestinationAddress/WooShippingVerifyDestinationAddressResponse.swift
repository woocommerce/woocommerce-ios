import Foundation

/// Represents Shipping Label Destination Address that has been validated or that generated an error from the WooCommerce Shipping Extension.
///
/// Only used internally for JSON decoding since the response might contain validation errors.
/// For public consumption, we'll convert those to a `WooShippingAddressValidationError`, and expose
/// a `WooShippingVerifyDestinationAddressSuccess` instead if there were no errors.
///
internal struct WooShippingVerifyDestinationAddressResponse: Equatable {
    let result: Result<WooShippingVerifyDestinationAddressSuccess, WooShippingAddressValidationError>

    init(normalizedAddress: WooShippingNormalizedAddress?,
         isTrivialNormalization: Bool?,
         isVerified: Bool?,
         errors: WooShippingAddressValidationError?) {
        if let errors {
            result = .failure(errors)
        } else if let normalizedAddress,
                  let isVerified {
            result = .success(.init(normalizedAddress: normalizedAddress,
                                    isTrivialNormalization: isTrivialNormalization,
                                    isVerified: isVerified))
        } else {
            // This case should never happen, but that's not guaranteed.
            // We'll treat the absence of both the addresses and errors as an error with no message.
            result = .failure(.init(addressError: nil, generalError: nil, nameError: nil))
        }
    }
}

extension WooShippingVerifyDestinationAddressResponse: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let normalizedAddress = try container.decodeIfPresent(WooShippingNormalizedAddress.self, forKey: .normalized)
        let isTrivialNormalization = try container.decodeIfPresent(Bool.self, forKey: .isTrivialNormalization)
        let isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified)
        let errors = try container.decodeIfPresent(WooShippingAddressValidationError.self, forKey: .errors)
        self.init(normalizedAddress: normalizedAddress,
                  isTrivialNormalization: isTrivialNormalization,
                  isVerified: isVerified,
                  errors: errors)
    }
}

/// Defines all of the WooShippingVerifyDestinationAddressResponse CodingKeys
///
private extension WooShippingVerifyDestinationAddressResponse {
    enum CodingKeys: String, CodingKey {
        case normalized = "normalizedAddress"
        case errors = "errors"
        case isTrivialNormalization = "isTrivialNormalization"
        case isVerified = "isVerified"
    }
}
