/// Protocol for `WooShippingRemote` mainly used for mocking.
///
public protocol WooShippingRemoteProtocol {
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage?,
                       predefinedOption: WooShippingPredefinedSavedOption?,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void)
    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: ShippingLabelAddress,
                        destinationAddress: ShippingLabelAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void)
    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void)
}

/// Shipping Labels Remote Endpoints for the WooShipping Plugin.
///
public final class WooShippingRemote: Remote, WooShippingRemoteProtocol {

    /// Creates a new custom package.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - customPackage: The custom package that should be created.
    ///   - predefinedOption: The predefined option (shipping provider and service packages) to activate.
    ///   - completion: Closure to be executed upon completion.
    public func createPackage(siteID: Int64,
                              customPackage: WooShippingCustomPackage?,
                              predefinedOption: WooShippingPredefinedSavedOption?,
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

    /// Loads shipping rates for a given order.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: ID of the order.
    ///   - originAddress: the origin address entity.
    ///   - destinationAddress: the destination address entity.
    ///   - packages: The package previously selected with all their data.
    ///   - completion: Closure to be executed upon completion.
    public func loadLabelRates(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackageSelected],
                               completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.orderID: orderID,
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: try packages.map { try $0.toDictionary() }
            ]
            let path = Path.rates
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = WooShippingLabelRatesMapper()

            enqueue(request, mapper: mapper, completion: completion)
        }
        catch {
            completion(.failure(error))
        }
    }

    /// Loads packages.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    public func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void) {
        do {
            let path = Path.packages
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .get,
                                         siteID: siteID,
                                         path: path,
                                         availableAsRESTRequest: true)

            let mapper = WooShippingPackagesMapper()

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
        static let rates = "label/rate"
    }

    enum ParameterKey {
        static let custom = "custom"
        static let predefined = "predefined"
        static let orderID = "order_id"
        static let originAddress = "origin"
        static let destinationAddress = "destination"
        static let packages = "packages"
    }
}

// MARK: Errors {
extension WooShippingRemote {
    enum ShippingError: Error {
        case missingPackage
    }
}
