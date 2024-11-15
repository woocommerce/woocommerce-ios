import Foundation
import Codegen

/// Represents store options, a list of saved Shipping Label Packages (custom and predefined) for the WooCommerce Shipping extension.
///
public struct WooShippingPackagesResponse: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Store options
    public let storeOptions: ShippingLabelStoreOptions

    /// Saved custom packages
    public let customPackages: [WooShippingCustomPackage]

    /// Saved (activated) predefined options
    public let savedPredefinedOptions: [WooShippingPredefinedSavedOption]

    /// All predefined options
    public let allPredefinedOptions: [WooShippingPredefinedOption]

    public init(storeOptions: ShippingLabelStoreOptions,
                customPackages: [WooShippingCustomPackage],
                savedPredefinedOptions: [WooShippingPredefinedSavedOption],
                allPredefinedOptions: [WooShippingPredefinedOption]) {
        self.storeOptions = storeOptions
        self.customPackages = customPackages
        self.savedPredefinedOptions = savedPredefinedOptions
        self.allPredefinedOptions = allPredefinedOptions
    }
}

// MARK: Decodable
extension WooShippingPackagesResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storeOptions = try container.decode(ShippingLabelStoreOptions.self, forKey: .storeOptions)
        let packagesData = try container.nestedContainer(keyedBy: PackagesKeys.self, forKey: .packages)

        let savedPackagesData = try packagesData.nestedContainer(keyedBy: SavedPackagesKeys.self, forKey: .saved)
        let customPackages = try savedPackagesData.decodeIfPresent([WooShippingCustomPackage].self, forKey: .custom) ?? []
        let rawSavedPredefinedOptions: [String: [String]] = savedPackagesData.failsafeDecodeIfPresent([String: [String]].self, forKey: .predefined) ?? [:]
        let savedPredefinedOptions = rawSavedPredefinedOptions.map { (carrier, packageIDs) in
            WooShippingPredefinedSavedOption(id: carrier, predefinedPackageIDs: packageIDs)
        }

        let allPredefinedPackagesData: [String: AnyCodable] = try packagesData.decode([String: AnyCodable].self, forKey: .predefined)
        var allPredefinedOptions: [WooShippingPredefinedOption] = []
        allPredefinedPackagesData.forEach { (key, value) in
            // key is a carrier id, for example "usps"
            if let provider: [String: Any]? = try? value.toDictionary() {
                provider?.forEach({ (providerKey, providerValue) in
                    // providerKey is package group id, for example "pri_flat_boxes"
                    let providerValueDict = providerValue as? [String: Any]
                    let title: String = providerValueDict?["title"] as? String ?? ""
                    let packages = WooShippingPackagesResponse.getAllPredefinedPackages(packageDefinitions: providerValueDict)
                    let option = WooShippingPredefinedOption(title: title, providerID: key, predefinedPackages: packages)
                    allPredefinedOptions.append(option)
                })
            }
        }

        self.init(storeOptions: storeOptions,
                  customPackages: customPackages,
                  savedPredefinedOptions: savedPredefinedOptions,
                  allPredefinedOptions: allPredefinedOptions)
    }

    static func getAllPredefinedPackages(packageDefinitions: [String: Any]?) -> [WooShippingPredefinedPackage] {
        guard let definitions = packageDefinitions?["definitions"], let jsonData = try? JSONSerialization.data(withJSONObject: definitions, options: []) else {
            return []
        }
        return (try? JSONDecoder().decode([WooShippingPredefinedPackage].self, from: jsonData)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case packages
        case predefined
        case storeOptions
    }

    private enum SavedPackagesKeys: String, CodingKey {
        case custom
        case predefined
    }

    private enum PackagesKeys: String, CodingKey {
        case predefined
        case saved
    }
}
