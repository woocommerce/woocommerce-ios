/// Protocol for `WooShippingRemote` mainly used for mocking.
///
public protocol WooShippingRemoteProtocol {
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage?,
                       predefinedOption: WooShippingPredefinedSavedOption?,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void)
    func deletePackage(siteID: Int64,
                       packageID: String,
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
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void)
    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void)
    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelID: Int64,
                          completion: @escaping (Result<ShippingLabelStatusPollingResponse, Error>) -> Void)
    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: ShippingLabelPaperSize,
                    completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void)
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

    public func deletePackage(siteID: Int64,
                              packageID: String,
                              completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        do {
            let path = "\(Path.packages)/\(packageID)"

            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .delete,
                                         siteID: siteID,
                                         path: path,
                                         parameters: nil,
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

            let mapper = WooShippingPackagesMapper(siteID: siteID)
            enqueue(request, mapper: mapper, completion: completion)
        }
    }

    /// Loads account settings.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccountSettings(siteID: Int64,
                                    completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
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
    ///   - originAddress: The origin address entity.
    ///   - destinationAddress: The destination address entity.
    ///   - package: The package previously selected with all its data.
    ///   - completion: Closure to be executed upon completion.
    public func purchaseShippingLabel(siteID: Int64,
                                      orderID: Int64,
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
                ParameterKey.selectedRate: try package.encodedShipmentRate(),
                ParameterKey.hazmat: package.encodedHazmat(),
                ParameterKey.customs: try package.encodedCustomsForm(),
            ]
            let path = "\(Path.purchase)/\(orderID)"
            let request = JetpackRequest(wooApiVersion: .wooShipping,
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

    /// Checks the shipping label status
    ///
    /// Used after purchasing a shipping label, to check for errors or confirm a successful purchase.
    /// This is used instead of loading all purchased labels for the order to ensure up-to-date (non-cached) results.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - orderID: Remote ID of the order that owns the shipping labels.
    ///     - labelID: Remote ID of the label to check the status of.
    ///     - completion: Closure to be executed upon completion.
    public func checkLabelStatus(siteID: Int64,
                                 orderID: Int64,
                                 labelID: Int64,
                                 completion: @escaping (Result<ShippingLabelStatusPollingResponse, Error>) -> Void) {
        let path = "\(Path.status)/\(orderID)/\(labelID)"
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = WooShippingStatusMapper(siteID: siteID, orderID: orderID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Generates shipping label data for printing.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping labels.
    ///   - labelIDs: Remote IDs of the shipping labels.
    ///   - paperSize: Paper size option (current options are "label", "legal", and "letter").
    ///   - completion: Closure to be executed upon completion.
    public func printLabel(siteID: Int64,
                           labelIDs: [Int64],
                           paperSize: ShippingLabelPaperSize,
                           completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.paperSize: paperSize.rawValue,
            ParameterKey.labelIDCSV: labelIDs.map(String.init).joined(separator: ",")
        ]
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.print,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ShippingLabelPrintDataMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: Constants
private extension WooShippingRemote {
    enum Path {
        static let packages = "packages"
        static let rates = "label/rate"
        static let accountSettings = "account/settings"
        static let purchase = "label/purchase"
        static let status = "label/status"
        static let print = "label/print"
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
        static let hazmat = "hazmat"
        static let customs = "customs"
        static let paperSize = "paper_size"
        static let labelIDCSV = "label_id_csv"
    }
}

// MARK: Errors {
extension WooShippingRemote {
    enum ShippingError: Error {
        case missingPackage
    }
}
