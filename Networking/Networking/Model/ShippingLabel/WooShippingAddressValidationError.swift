import Foundation
import Codegen

/// Represents Shipping Label Address Validation Error from the WooCommerce Shipping extension.
///
public struct WooShippingAddressValidationError: Error, Equatable {
    public let addressError: String?
    public let generalError: String?
    public let nameError: String?

    public init(addressError: String?, generalError: String?, nameError: String?) {
        self.addressError = addressError
        self.generalError = generalError
        self.nameError = nameError
    }
}

extension WooShippingAddressValidationError: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addressError = try container.decodeIfPresent(String.self, forKey: .address)
        let generalError = try container.decodeIfPresent(String.self, forKey: .general)
        let nameError = try container.decodeIfPresent(String.self, forKey: .name)
        self.init(addressError: addressError, generalError: generalError, nameError: nameError)
    }
}

/// Defines all of the WooShippingAddressValidationError CodingKeys
///
private extension WooShippingAddressValidationError {
    enum CodingKeys: String, CodingKey {
        case general
        case address
        case name
    }
}
