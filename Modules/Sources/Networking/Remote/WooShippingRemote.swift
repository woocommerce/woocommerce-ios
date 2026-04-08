/// Enum for package types supported by WooShipping
///
public enum WooShippingPackageType: String {
    case custom
    case predefined
}

/// Protocol for `WooShippingRemote` mainly used for mocking.
///
public protocol WooShippingRemoteProtocol {
    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void)
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage?,
                       predefinedOption: WooShippingPredefinedSavedOption?,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void)
    func deletePackage(siteID: Int64,
                       packageID: String,
                       packageType: WooShippingPackageType,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void)
    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: WooShippingAddress,
                        destinationAddress: WooShippingAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void)
    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void)
    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void)
    func updateAccountSettings(siteID: Int64,
                               settings: ShippingLabelAccountSettings,
                               completion: @escaping (Result<Bool, Error>) -> Void)
    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: WooShippingAddress,
                               destinationAddress: WooShippingAddress,
                               package: WooShippingPackagePurchase,
                               markOrderComplete: Bool?,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void)
    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelID: Int64,
                          completion: @escaping (Result<ShippingLabelStatusPollingResponse, Error>) -> Void)
    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: ShippingLabelPaperSize,
                    completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void)

    func loadOriginAddresses(siteID: Int64,
                             completion: @escaping (Result<[WooShippingOriginAddress], Error>) -> Void)
    func addressValidation(siteID: Int64,
                           address: WooShippingAddress,
                           completion: @escaping (Result<WooShippingAddressValidationSuccess, Error>) -> Void)
    func updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: @escaping (Result<WooShippingOriginAddressUpdate, Error>) -> Void)
    func verifyDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<WooShippingVerifyDestinationAddressSuccess, Error>) -> Void)
    func updateDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  address: WooShippingDestinationAddress,
                                  isVerified: Bool,
                                  completion: @escaping (Result<WooShippingDestinationAddressUpdate, Error>) -> Void)
    func loadConfig(siteID: Int64,
                    orderID: Int64,
                    completion: @escaping (Result<WooShippingConfig, Error>) -> Void)
    func updateShipment(siteID: Int64,
                        orderID: Int64,
                        shipmentToUpdate: WooShippingUpdateShipment,
                        completion: @escaping (Result<WooShippingShipments, Error>) -> Void)

    func refundShippingLabel(siteID: Int64,
                             orderID: Int64,
                             shippingLabelID: Int64,
                             completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void)

    func acceptUPSTermsOfService(siteID: Int64,
                                 originAddress: WooShippingAddress,
                                 completion: @escaping(Result<Bool, Error>) -> Void)

    func acceptFedExTermsOfService(siteID: Int64,
                                   completion: @escaping(Result<Bool, Error>) -> Void)
}

/// Shipping Labels Remote Endpoints for the WooShipping Plugin.
///
public final class WooShippingRemote: Remote, WooShippingRemoteProtocol {

    /// Checks eligibility for shipping label creation.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - orderID: Remote ID of the order that owns the shipping labels.
    ///     - completion: Closure to be executed upon completion.
    public func checkCreationEligibility(siteID: Int64,
                                         orderID: Int64,
                                         completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void) {
        let path = "\(Path.eligibility)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = ShippingLabelCreationEligibilityMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

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
                              packageType: WooShippingPackageType,
                              completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        let path = [Path.packages, packageType.rawValue, packageID].joined(separator: "/")

        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .delete,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)

        let mapper = WooShippingCreatePackageMapper()

        enqueue(request, mapper: mapper, completion: completion)
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
                               originAddress: WooShippingAddress,
                               destinationAddress: WooShippingAddress,
                               packages: [ShippingLabelPackageSelected],
                               completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.orderID: orderID,
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: try packages.map { try $0.toDictionary() },
                ParameterKey.featuresSupported: [Values.upsdap, Values.fedex]
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
            let parameters: [String: Any] = [
                ParameterKey.featuresSupported: [Values.upsdap, Values.fedex]
            ]
            let path = Path.packages
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .get,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
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
        let path = Path.accountSettings
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)

        let mapper = WooShippingAccountSettingsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates account-level settings for a store.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - settings: The shipping label account settings to update remotely.
    ///     - completion: Closure to be executed upon completion.
    public func updateAccountSettings(siteID: Int64,
                                      settings: ShippingLabelAccountSettings,
                                      completion: @escaping (Result<Bool, Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.selectedPaymentMethodID: settings.selectedPaymentMethodID,
            ParameterKey.emailReceipts: settings.isEmailReceiptsEnabled,
            ParameterKey.enabled: true // This is needed due to the bug WOOSHIP-1410
        ]
        let path = Path.accountSettings
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SuccessDataResultMapper()
        enqueue(request, mapper: mapper, completion: completion)
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
                                      originAddress: WooShippingAddress,
                                      destinationAddress: WooShippingAddress,
                                      package: WooShippingPackagePurchase,
                                      markOrderComplete: Bool?,
                                      completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {
        let userMeta: [String: Any]? = {
            guard let markOrderComplete else {
                return nil
            }
            return [ParameterKey.lastOrderCompleted: markOrderComplete]
        }()
        do {
            let parameters: [String: Any] = [
                ParameterKey.async: true,
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: [ try package.toDictionary() ],
                ParameterKey.selectedRate: try package.encodedShipmentRate(),
                ParameterKey.selectedRateOptions: package.selectedRateOptions,
                ParameterKey.featuresSupported: [Values.upsdap, Values.fedex],
                ParameterKey.hazmat: package.encodedHazmat(),
                ParameterKey.customs: try package.encodedCustomsForm(),
                ParameterKey.userMeta: userMeta,
            ].compactMapValues { $0 }
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

    /// Loads origin addresses.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    public func loadOriginAddresses(siteID: Int64, completion: @escaping (Result<[WooShippingOriginAddress], any Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.originAddresses,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = WooShippingOriginAddressesMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Address validation for a shipping address.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - address: The address that should be verified.
    ///   - completion: Closure to be executed upon completion.
    public func addressValidation(siteID: Int64,
                                  address: WooShippingAddress,
                                  completion: @escaping (Result<WooShippingAddressValidationSuccess, Error>) -> Void) {
        do {
            let parameters = [
                ParameterKey.address: try address.toDictionary()
            ]
            let path = "\(Path.normalizeAddress)"
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = WooShippingAddressValidationSuccessMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Updates an origin address.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - address: The updated origin address.
    ///   - isVerified: Whether the address has been remotely verified.
    ///   - completion: Closure to be executed upon completion.
    public func updateOriginAddress(siteID: Int64,
                                    address: WooShippingOriginAddress,
                                    isVerified: Bool,
                                    completion: @escaping (Result<WooShippingOriginAddressUpdate, Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.address: try address.toDictionary(),
                ParameterKey.isVerified: isVerified
            ]
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: Path.updateOrigin,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = WooShippingOriginAddressUpdateMapper(siteID: siteID)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Verifies the destination address of an order.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order.
    ///   - completion: Closure to be executed upon completion.
    public func verifyDestinationAddress(siteID: Int64,
                                         orderID: Int64,
                                         completion: @escaping (Result<WooShippingVerifyDestinationAddressSuccess, Error>) -> Void) {
        let path = Path.verifyOrder(orderID: orderID)
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = WooShippingVerifyDestinationAddressMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates a destination address.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order.
    ///   - address: The updated destination address.
    ///   - completion: Closure to be executed upon completion.
    public func updateDestinationAddress(siteID: Int64,
                                         orderID: Int64,
                                         address: WooShippingDestinationAddress,
                                         isVerified: Bool,
                                         completion: @escaping (Result<WooShippingDestinationAddressUpdate, Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.address: try address.toDictionary(),
                ParameterKey.isVerified: isVerified
            ]
            let path = Path.updateDestination(orderID: orderID)
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = WooShippingDestinationAddressUpdateMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Loads label config for a given order
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order.
    ///   - completion: Closure to be executed upon completion.
    public func loadConfig(siteID: Int64,
                           orderID: Int64,
                           completion: @escaping (Result<WooShippingConfig, Error>) -> Void) {
        do {
            let path = Path.config(orderID: orderID)
            let parameters = [
                ParameterKey.fields: WooShippingConfigMapper.fieldsToLoad
            ]
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .get,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)

            let mapper = WooShippingConfigMapper(siteID: siteID, orderID: orderID)
            enqueue(request, mapper: mapper, completion: completion)
        }
    }

    /// Updates shipment for a given order
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order.
    ///   - shipmentToUpdate: shipment info to send to remote
    ///   - completion: Closure to be executed upon completion.
    public func updateShipment(siteID: Int64,
                               orderID: Int64,
                               shipmentToUpdate: WooShippingUpdateShipment,
                               completion: @escaping (Result<WooShippingShipments, Error>) -> Void) {
        do {
            let parameters = try shipmentToUpdate.toDictionary()
            let path = Path.updateShipment(orderID: orderID)
            let request = JetpackRequest(wooApiVersion: .wooShipping,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
            let mapper = WooShippingUpdateShipmentMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Requests a refund for a shipping label.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - orderID: Remote ID of the order that owns the shipping labels.
    ///   - shippingLabelID: Remote ID of the shipping label.
    ///   - completion: Closure to be executed upon completion.
    public func refundShippingLabel(siteID: Int64,
                                    orderID: Int64,
                                    shippingLabelID: Int64,
                                    completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        let path = Path.refundLabel(orderID: orderID, labelID: shippingLabelID)
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = ShippingLabelRefundMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the Terms of Service agreement status for a specific origin address in the UPS DAP carrier strategies.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - originAddress: The origin address to accept the TOS.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func acceptUPSTermsOfService(siteID: Int64,
                                        originAddress: WooShippingAddress,
                                        completion: @escaping(Result<Bool, Error>) -> Void) {
        do {
            let path = Path.upsdapCarrierStrategy
            let parameters: [String: Any] = [
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.confirmed: true
            ]
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

    /// Accepts the FedEx Terms of Service.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func acceptFedExTermsOfService(siteID: Int64,
                                          completion: @escaping(Result<Bool, Error>) -> Void) {
        let path = Path.fedexCarrierStrategy
        let parameters: [String: Any] = [
            ParameterKey.confirmed: true
        ]
        let request = JetpackRequest(wooApiVersion: .wooShipping,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SuccessDataResultMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: Constants
private extension WooShippingRemote {
    enum Path {
        static let eligibility = "eligibility"
        static let packages = "packages"
        static let rates = "label/rate"
        static let accountSettings = "account/settings"
        static let purchase = "label/purchase"
        static let status = "label/status"
        static let print = "label/print"
        static let originAddresses = "address/origins"
        static let normalizeAddress = "address/normalize"
        static let updateOrigin = "address/update_origin"
        static func verifyOrder(orderID: Int64) -> String {
            "address/\(orderID)/verify_order"
        }
        static func updateDestination(orderID: Int64) -> String {
            "address/\(orderID)/update_destination"
        }
        static func config(orderID: Int64) -> String {
            "config/label-purchase/\(orderID)"
        }
        static func updateShipment(orderID: Int64) -> String {
            "shipments/\(orderID)"
        }
        static func refundLabel(orderID: Int64, labelID: Int64) -> String {
            "label/refund/\(orderID)/\(labelID)"
        }
        static let upsdapCarrierStrategy = "carrier-strategy/upsdap"
        static let fedexCarrierStrategy = "carrier-strategy/fedex"
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
        static let selectedRateOptions = "selected_rate_options"
        static let hazmat = "hazmat"
        static let customs = "customs"
        static let paperSize = "paper_size"
        static let labelIDCSV = "label_id_csv"
        static let address = "address"
        static let isVerified = "isVerified"
        static let fields = "_fields"
        static let selectedPaymentMethodID = "selected_payment_method_id"
        static let emailReceipts = "email_receipts"
        static let enabled = "enabled"
        static let featuresSupported = "features_supported_by_client"
        static let confirmed = "confirmed"
        static let userMeta = "user_meta"
        static let lastOrderCompleted = "last_order_completed"
    }

    enum Values {
        static let upsdap = "upsdap"
        static let fedex = "fedex"
    }
}

// MARK: Errors {
extension WooShippingRemote {
    enum ShippingError: Error {
        case missingPackage
    }
}
