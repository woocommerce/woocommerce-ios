import Foundation
import Codegen

/// Represents Account Settings for Shipping Labels.
///
public struct WooShippingAccountSettingsResponse: Equatable, GeneratedFakeable, GeneratedCopiable {
    public let storeOptions: ShippingLabelStoreOptions

    public init(storeOptions: ShippingLabelStoreOptions) {
        self.storeOptions = storeOptions
    }
}

extension WooShippingAccountSettingsResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storeOptions = try container.decode(ShippingLabelStoreOptions.self, forKey: .storeOptions)

        self.init(storeOptions: storeOptions)
    }

    private enum CodingKeys: String, CodingKey {
        case storeOptions
    }
}
