import Foundation
import Codegen

/// Represents a list of saved Shipping Label Packages (custom and predefined) for the WooCommerce Shipping extension.
///
public struct WooShippingCreatePackageResponse: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Saved custom packages
    public let customPackages: [WooShippingCustomPackage]

    /// Saved (activated) predefined options
    public let predefinedOptions: [WooShippingPredefinedSavedOption]

    public init(customPackages: [WooShippingCustomPackage],
                predefinedOptions: [WooShippingPredefinedSavedOption]) {
        self.customPackages = customPackages
        self.predefinedOptions = predefinedOptions
    }
}

// MARK: Decodable
extension WooShippingCreatePackageResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let customPackages = try container.decodeIfPresent([WooShippingCustomPackage].self, forKey: .custom) ?? []

        // We assume that rows will always be of type `Dictionary<String:<Array<String>>>`
        //
        let rawPredefinedOptions: [String: [String]] = container.failsafeDecodeIfPresent([String: [String]].self, forKey: .predefined) ?? [:]

        let predefinedOptions = rawPredefinedOptions.map { (carrier, packageIDs) in
            WooShippingPredefinedSavedOption(id: carrier, predefinedPackageIDs: packageIDs)
        }

        self.init(customPackages: customPackages,
                  predefinedOptions: predefinedOptions)
    }

    private enum CodingKeys: String, CodingKey {
        case custom
        case predefined
    }
}
