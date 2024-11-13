import Foundation
import Codegen

/// Represents store options, a list of saved Shipping Label Packages (custom and predefined) for the WooCommerce Shipping extension.
///
public struct WooShippingPackagesResponse: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Store options
    public let storeOptions: ShippingLabelStoreOptions?

    /// Saved custom packages
    public let customPackages: [WooShippingCustomPackage]

    /// Saved (activated) predefined options
    public let predefinedOptions: [WooShippingPredefinedOption]

    public init(storeOptions: ShippingLabelStoreOptions?,
                customPackages: [WooShippingCustomPackage],
                predefinedOptions: [WooShippingPredefinedOption]) {
        self.storeOptions = storeOptions
        self.customPackages = customPackages
        self.predefinedOptions = predefinedOptions
    }
}

// MARK: Decodable
extension WooShippingPackagesResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storeOptions = try container.decodeIfPresent(ShippingLabelStoreOptions.self, forKey: .storeOptions)

        let customPackages = try container.decodeIfPresent([WooShippingCustomPackage].self, forKey: .custom) ?? []

        // We assume that rows will always be of type `Dictionary<String:<Array<String>>>`
        //
        let rawPredefinedOptions: [String: [String]] = container.failsafeDecodeIfPresent([String: [String]].self, forKey: .predefined) ?? [:]

        let predefinedOptions = rawPredefinedOptions.map { (carrier, packageIDs) in
            WooShippingPredefinedOption(id: carrier, predefinedPackageIDs: packageIDs)
        }

        self.init(storeOptions: storeOptions,
                  customPackages: customPackages,
                  predefinedOptions: predefinedOptions)
    }

    private enum CodingKeys: String, CodingKey {
        case custom
        case predefined
        case storeOptions
    }
}
