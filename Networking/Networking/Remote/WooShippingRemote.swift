/// Shipping Labels Remote Endpoints for the WooShipping Plugin.
///
public final class WooShippingRemote: Remote {

    /// Creates a new custom package.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - customPackage: The custom package that should be created.
    ///   - predefinedOption: The predefined option (shipping provider and service packages) to activate.
    ///   - completion: Closure to be executed upon completion.
    public func createPackage(siteID: Int64,
                              customPackage: ShippingLabelCustomPackage?,
                              predefinedOption: ShippingLabelPredefinedOption?,
                              completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            var customPackageList: [[String: Any]] = []
            var predefinedOptionDictionary: [String: [String]] = [:]

            if let customPackage = customPackage {
                let customPackageDictionary = try customPackage.toDictionary()
                customPackageList = [customPackageDictionary]
            } else if let predefinedOption = predefinedOption {
                let packageIDs = predefinedOption.predefinedPackages.map({ $0.id })
                predefinedOptionDictionary = [predefinedOption.providerID: packageIDs]
            } else {
                throw ShippingLabelError.missingPackage
            }

            let parameters: [String: Any] = [
                ParameterKey.custom: customPackageList,
                ParameterKey.predefined: predefinedOptionDictionary
            ]
            let path = Path.packages
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = SuccessDataResultMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: Constants
private extension WooShippingRemote {
    enum Path {
        static let packages = "packages"
    }

    enum ParameterKey {
        static let custom = "custom"
        static let predefined = "predefined"
    }
}

// MARK: Errors {
extension WooShippingRemote {
    enum ShippingLabelError: Error {
        case missingPackage
    }
}
