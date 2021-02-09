import Foundation

/// Represents Shipping Label Address Validation Error.
///
public struct ShippingLabelAddressValidationError: Equatable {
    public let address: String?
    public let general: String?

    public init(address: String?, general: String?) {
        self.address = address
        self.general = general
    }
}

extension ShippingLabelAddressValidationError: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decodeIfPresent(String.self, forKey: .address)
        let general = try container.decodeIfPresent(String.self, forKey: .general)
        self.init(address: address, general: general)
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
