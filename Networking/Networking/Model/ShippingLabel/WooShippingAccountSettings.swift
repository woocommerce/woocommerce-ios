import Foundation
import Codegen

/// Represents Account Settings for Shipping Labels.
///
public struct WooShippingAccountSettings: Equatable, GeneratedFakeable, GeneratedCopiable {
    public let storeOptions: ShippingLabelStoreOptions
    public let accountSettings: ShippingLabelAccountSettings
//
    public init(storeOptions: ShippingLabelStoreOptions, accountSettings: ShippingLabelAccountSettings) {
        self.storeOptions = storeOptions
        self.accountSettings = accountSettings
    }
}

extension WooShippingAccountSettings: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storeOptions = try container.decode(ShippingLabelStoreOptions.self, forKey: .storeOptions)
        let accountSettings = try ShippingLabelAccountSettings(from: decoder)

        self.init(storeOptions: storeOptions, accountSettings: accountSettings)
    }

    private enum CodingKeys: String, CodingKey {
        case storeOptions
    }
}
