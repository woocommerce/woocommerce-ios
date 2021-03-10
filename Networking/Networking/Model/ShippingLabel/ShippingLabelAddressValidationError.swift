import Foundation

/// Represents Shipping Label Address Validation Error.
///
public struct ShippingLabelAddressValidationError: Equatable, GeneratedFakeable {
    public let addressError: String?
    public let generalError: String?

    public init(addressError: String?, generalError: String?) {
        self.addressError = addressError
        self.generalError = generalError
    }
}

extension ShippingLabelAddressValidationError: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addressError = try container.decodeIfPresent(String.self, forKey: .address)
        let generalError = try container.decodeIfPresent(String.self, forKey: .general)
        self.init(addressError: addressError, generalError: generalError)
    }
}

/// Defines all of the ShippingLabelAddressValidationError CodingKeys
///
private extension ShippingLabelAddressValidationError {
    enum CodingKeys: String, CodingKey {
        case address
        case general
    }
}
