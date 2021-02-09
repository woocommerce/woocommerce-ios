import Foundation

/// Represents Shipping Label Address that has been validated.
///
public struct ShippingLabelAddressValidationResponse: Equatable {
    public let address: ShippingLabelAddress

    public init(address: ShippingLabelAddress) {
        self.address = address
    }
}

extension ShippingLabelAddressValidationResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(ShippingLabelAddress.self, forKey: .address)
        self.init(address: address)
    }
}

/// Defines all of the ShippingLabelAddressValidationResponse CodingKeys
///
private extension ShippingLabelAddressValidationResponse {
    enum CodingKeys: String, CodingKey {
        case address = "normalized"
    }
}
