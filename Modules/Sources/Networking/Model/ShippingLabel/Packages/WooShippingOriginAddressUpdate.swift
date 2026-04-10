import Foundation
import Codegen

/// Represents the response when an origin address is updated in the WooCommerce Shipping extension.
public struct WooShippingOriginAddressUpdate: Equatable {
    public let address: WooShippingOriginAddress
    public let isVerified: Bool

    public init(address: WooShippingOriginAddress,
                isVerified: Bool) {
        self.address = address
        self.isVerified = isVerified
    }
}

// MARK: Decodable
extension WooShippingOriginAddressUpdate: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let address = try container.decode(WooShippingOriginAddress.self, forKey: .address)
        let isVerified = try container.decode(Bool.self, forKey: .isVerified)

        self.init(address: address,
                  isVerified: isVerified)
    }

    private enum CodingKeys: String, CodingKey {
        case address
        case isVerified
    }
}
