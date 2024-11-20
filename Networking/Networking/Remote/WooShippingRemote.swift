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
    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettingsResponse, Error>) -> Void)
    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               shipmentID: String,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void)
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

    /// Loads account settings.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccountSettings(siteID: Int64,
                                    completion: @escaping (Result<WooShippingAccountSettingsResponse, Error>) -> Void) {
        do {
            let path = Path.accountSettings
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .get,
                                         siteID: siteID,
                                         path: path,
                                         availableAsRESTRequest: true)

            let mapper = WooShippingAccountSettingsMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Initiates a shipping label purchase.
    ///
    /// This request returns the label purchase data, including a `PURCHASE_IN_PROGRESS` status.
    /// After initiating the purchase, we must poll the backend for the updated label status (successful purchase or error).
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order that owns the shipping labels.
    ///   - shipmentID: Remote ID of the shipment getting a label.
    ///   - originAddress: The origin address entity.
    ///   - destinationAddress: The destination address entity.
    ///   - package: The package previously selected with all its data.
    ///   - completion: Closure to be executed upon completion.
    public func purchaseShippingLabel(siteID: Int64,
                                      orderID: Int64,
                                      shipmentID: String,
                                      originAddress: ShippingLabelAddress,
                                      destinationAddress: ShippingLabelAddress,
                                      package: WooShippingPackagePurchase,
                                      completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.async: true,
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: [ try package.toDictionary() ],
                ParameterKey.selectedRate: [shipmentID: [ParameterKey.rate: try package.rate.toDictionary()]],
                ParameterKey.hazmat: {}, // Hazmat support TBD (Milestone 3)
                ParameterKey.customs: {}, // Customs support TBD (Milestone 2)
                ParameterKey.userMeta: {} // TODO: 13558 - Add user meta when we have account settings support
            ]
            let path = "\(Path.purchase)/\(orderID)"
            let request = JetpackRequest(wooApiVersion: .wcConnectV1,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = ShippingLabelPurchaseMapper(siteID: siteID, orderID: orderID)
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
        static let accountSettings = "account/settings"
        static let purchase = "label/purchase"
    }

    enum ParameterKey {
        static let custom = "custom"
        static let predefined = "predefined"
        static let orderID = "order_id"
        static let originAddress = "origin"
        static let destinationAddress = "destination"
        static let packages = "packages"
        static let async = "async"
        static let selectedRate = "selected_rate"
        static let rate = "rate"
        static let hazmat = "hazmat"
        static let customs = "customs"
        static let userMeta = "user_meta"
    }
}

// MARK: Errors {
extension WooShippingRemote {
    enum ShippingError: Error {
        case missingPackage
    }
}
