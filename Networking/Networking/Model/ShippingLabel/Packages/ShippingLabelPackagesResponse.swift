import Foundation
import Codegen

/// Represents a list of Shipping Label Packages (custom and predefined).
///
public struct ShippingLabelPackagesResponse: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// The options of the store, like currency symbol and origin country.
    public let storeOptions: ShippingLabelStoreOptions

    public let customPackages: [ShippingLabelCustomPackage]

    /// Activated predefined options
    public let predefinedOptions: [ShippingLabelPredefinedOption]

    /// Unactivated predefined options
    public let unactivatedPredefinedOptions: [ShippingLabelPredefinedOption]

    public init(storeOptions: ShippingLabelStoreOptions,
                customPackages: [ShippingLabelCustomPackage],
                predefinedOptions: [ShippingLabelPredefinedOption],
                unactivatedPredefinedOptions: [ShippingLabelPredefinedOption]) {
        self.storeOptions = storeOptions
        self.customPackages = customPackages
        self.predefinedOptions = predefinedOptions
        self.unactivatedPredefinedOptions = unactivatedPredefinedOptions
    }
}

// MARK: Decodable
extension ShippingLabelPackagesResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let mainContainer = try decoder.container(keyedBy: CodingKeys.self)

        let storeOptions = try mainContainer.decode(ShippingLabelStoreOptions.self, forKey: .storeOptions)
        let formDataContainer = try mainContainer.nestedContainer(keyedBy: FormDataKeys.self, forKey: .formData)
        let customPackages = try formDataContainer.decodeIfPresent([ShippingLabelCustomPackage].self, forKey: .custom) ?? []

        let formSchemaContainer = try mainContainer.nestedContainer(keyedBy: FormSchemaKeys.self, forKey: .formSchema)



        // We assume that rows will always be of type `Dictionary<String:<Array<String>>>`
        //
        let rawPredefinedFormData: [String: AnyCodable] = formDataContainer.failsafeDecodeIfPresent([String: AnyCodable].self, forKey: .predefined) ?? [:]

        // We assume that rows will always be of type `Dictionary<String:<Dictionary<String: Dictionary<different values>>>`
        //
        let rawPredefinedFormSchema: [String: AnyCodable] = formSchemaContainer.failsafeDecodeIfPresent([String: AnyCodable].self, forKey: .predefined) ?? [:]


        var predefinedOptions: [ShippingLabelPredefinedOption] = []
        var unactivatedPredefinedOptions: [ShippingLabelPredefinedOption] = []

        // Iterate around keys of `formSchema` and `formData` for creating the predefined options available for this website.
        //
        rawPredefinedFormSchema.forEach { (key, value) in

            let provider: [String: Any]? = try? value.toDictionary()
            provider?.forEach({ (providerKey, providerValue) in

                let providerValueDict = providerValue as? [String: Any]
                let packages = ShippingLabelPackagesResponse.getAllPredefinedPackages(packageDefinitions: providerValueDict)

                let packageIDs: [Any?] = rawPredefinedFormData[key]?.value as? [Any?] ?? []
                let activatedPredefinedPackages = ShippingLabelPackagesResponse.getPredefinedPackages(withIDs: packageIDs, in: packages)

                if !activatedPredefinedPackages.isEmpty {
                    let titleOption: String = providerValueDict?["title"] as? String ?? ""
                    let option = ShippingLabelPredefinedOption(title: titleOption, providerID: key, predefinedPackages: activatedPredefinedPackages)
                    predefinedOptions.append(option)
                }

                let unactivatedPredefinedPackages = packages.filter({ !activatedPredefinedPackages.contains($0) })

                if !unactivatedPredefinedPackages.isEmpty {
                    let titleOption: String = providerValueDict?["title"] as? String ?? ""
                    let option = ShippingLabelPredefinedOption(title: titleOption, providerID: key, predefinedPackages: unactivatedPredefinedPackages)
                    unactivatedPredefinedOptions.append(option)
                }
            })
        }

        self.init(storeOptions: storeOptions,
                  customPackages: customPackages,
                  predefinedOptions: predefinedOptions,
                  unactivatedPredefinedOptions: unactivatedPredefinedOptions)
    }

    private enum CodingKeys: String, CodingKey {
        case storeOptions
        case formData
        case formSchema
    }

    private enum FormDataKeys: String, CodingKey {
        case custom
        case predefined
    }

    private enum FormSchemaKeys: String, CodingKey {
        case predefined
    }
}

private extension ShippingLabelPackagesResponse {
    /// Get activated predefined packages
    ///
    static func getPredefinedPackages(withIDs packageIDs: [Any?], in packages: [ShippingLabelPredefinedPackage]) -> [ShippingLabelPredefinedPackage] {
        var predefinedPackages: [ShippingLabelPredefinedPackage] = []

        packageIDs.compactMap { $0 }.forEach { (packageID) in
            packages.forEach { (package) in
                if packageID as? String == package.id {
                    predefinedPackages.append(package)
                }
            }
        }
        return predefinedPackages
    }

    /// Get all possible predefined packages (including those not activated on the store)
    ///
    static func getAllPredefinedPackages(packageDefinitions: [String: Any]?) -> [ShippingLabelPredefinedPackage] {
        guard let definitions = packageDefinitions?["definitions"], let jsonData = try? JSONSerialization.data(withJSONObject: definitions, options: []) else {
            return []
        }
        return (try? JSONDecoder().decode([ShippingLabelPredefinedPackage].self, from: jsonData)) ?? []
    }
}
