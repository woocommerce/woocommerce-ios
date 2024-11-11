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
                              customPackage: WooShippingCustomPackage?,
                              predefinedOption: WooShippingPredefinedOption?,
                              completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        do {
            var customPackageList: [[String: Any]] = []
            var predefinedOptionDictionary: [String: [String]] = [:]

            if let customPackage {
                let customPackageDictionary = try customPackage.toDictionary()
                customPackageList = [customPackageDictionary]
            } else if let predefinedOption {
                predefinedOptionDictionary = [predefinedOption.id: predefinedOption.predefinedPackageIDs]
            } else {
                throw ShippingError.missingPackage
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

            let mapper = WooShippingCreatePackageMapper()

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
    enum ShippingError: Error {
        case missingPackage
    }
}
