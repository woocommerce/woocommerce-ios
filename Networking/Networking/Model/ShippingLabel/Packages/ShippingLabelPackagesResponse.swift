import Foundation

/// Represents a list of Shipping Label Packages (custom and predefined).
///
public struct ShippingLabelPackagesResponse: Equatable, GeneratedFakeable {

    /// The options of the store, like currency symbol and origin country.
    public let storeOptions: ShippingLabelStoreOptions

    public let customPackages: [ShippingLabelCustomPackage]

    public let predefinedOptions: [ShippingLabelPredefinedOption]

    public init(storeOptions: ShippingLabelStoreOptions,
                customPackages: [ShippingLabelCustomPackage],
                predefinedOptions: [ShippingLabelPredefinedOption]) {
        self.storeOptions = storeOptions
        self.customPackages = customPackages
        self.predefinedOptions = predefinedOptions
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
        let rawPredefinedFormData: [String: AnyCodable] = try formDataContainer.decodeIfPresent([String: AnyCodable].self, forKey: .predefined) ?? [:]

        // We assume that rows will always be of type `Dictionary<String:<Dictionary<String: Dictionary<different values>>>`
        //
        let rawPredefinedFormSchema: [String: AnyCodable] = try formSchemaContainer.decodeIfPresent([String: AnyCodable].self, forKey: .predefined) ?? [:]


        var predefinedOptions: [ShippingLabelPredefinedOption] = []

        // Iterate around keys of `formSchema` and `formData` for creating the predefined options available for this website.
        //
        rawPredefinedFormSchema.forEach { (key, value) in

            let provider: [String: Any]? = try? value.toDictionary()
            provider?.forEach({ (providerKey, providerValue) in

                let packageIDs: [Any?] = rawPredefinedFormData[key]?.value as? [Any?] ?? []
                let providerValueDict = providerValue as? [String: Any]
                let predefinedPackages = ShippingLabelPackagesResponse.getPredefinedPackages(packageIDs: packageIDs,
                                                                                             packageDefinitions: providerValueDict)
                if !predefinedPackages.isEmpty {
                    let titleOption: String = providerValueDict?["title"] as? String ?? ""
                    let option = ShippingLabelPredefinedOption(title: titleOption, predefinedPackages: predefinedPackages)
                    predefinedOptions.append(option)
                }
            })
        }

        self.init(storeOptions: storeOptions, customPackages: customPackages, predefinedOptions: predefinedOptions)
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
    static func getPredefinedPackages(packageIDs: [Any?], packageDefinitions: [String: Any]?) -> [ShippingLabelPredefinedPackage] {
        var predefinedPackages: [ShippingLabelPredefinedPackage] = []
        guard let definitions = packageDefinitions?["definitions"], let jsonData = try? JSONSerialization.data(withJSONObject: definitions, options: []) else {
            return []
        }
        let packages = (try? JSONDecoder().decode([ShippingLabelPredefinedPackage].self, from: jsonData)) ?? []

        packageIDs.compactMap { $0 }.forEach { (packageID) in
            packages.forEach { (package) in
                if packageID as? String == package.id {
                    predefinedPackages.append(package)
                }
            }
        }
        return predefinedPackages
    }
}
