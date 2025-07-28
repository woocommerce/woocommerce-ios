import Foundation
import Codegen

/// Represents the response when an Destination address is updated in the WooCommerce Shipping extension.
public struct WooShippingDestinationAddressUpdate: Equatable {
    public let address: WooShippingDestinationAddress
    public let isVerified: Bool

    public init(address: WooShippingDestinationAddress,
                isVerified: Bool) {
        self.address = address
        self.isVerified = isVerified
    }
}

// MARK: Decodable
extension WooShippingDestinationAddressUpdate: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let address = try container.decode(WooShippingDestinationAddress.self, forKey: .address)
        let isVerified = try container.decode(Bool.self, forKey: .isVerified)

        self.init(address: address,
                  isVerified: isVerified)
    }

    private enum CodingKeys: String, CodingKey {
        case address
        case isVerified
    }
}
