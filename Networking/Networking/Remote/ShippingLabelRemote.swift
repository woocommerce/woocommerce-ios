import Foundation

/// Protocol for `ShippingLabelRemote` mainly used for mocking.
public protocol ShippingLabelRemoteProtocol {
    func loadShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<OrderShippingLabelListResponse, Error>) -> Void)
    func printShippingLabel(siteID: Int64,
                            shippingLabelIDs: [Int64],
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void)
    func refundShippingLabel(siteID: Int64,
                             orderID: Int64,
                             shippingLabelID: Int64,
                             completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void)
    func addressValidation(siteID: Int64,
                           address: ShippingLabelAddressVerification,
                           completion: @escaping (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void)
    func packagesDetails(siteID: Int64,
                         completion: @escaping (Result<ShippingLabelPackagesResponse, Error>) -> Void)
    func createPackage(siteID: Int64,
                       customPackage: ShippingLabelCustomPackage?,
                       predefinedOption: ShippingLabelPredefinedOption?,
                       completion: @escaping (Result<Bool, Error>) -> Void)
    func loadCarriersAndRates(siteID: Int64,
                              orderID: Int64,
                              originAddress: ShippingLabelAddress,
                              destinationAddress: ShippingLabelAddress,
                              packages: [ShippingLabelPackageSelected],
                              completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void)
    func loadShippingLabelAccountSettings(siteID: Int64,
                                          completion: @escaping (Result<ShippingLabelAccountSettings, Error>) -> Void)
    func updateShippingLabelAccountSettings(siteID: Int64,
                                            settings: ShippingLabelAccountSettings,
                                            completion: @escaping (Result<Bool, Error>) -> Void)
    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  canCreatePaymentMethod: Bool,
                                  canCreateCustomsForm: Bool,
                                  canCreatePackage: Bool,
                                  completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void)
    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackagePurchase],
                               emailCustomerReceipt: Bool,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void)
    func checkLabelStatus(siteID: Int64,
                             orderID: Int64,
                             labelIDs: [Int64],
                             completion: @escaping (Result<[ShippingLabelStatusPollingResponse], Error>) -> Void)
    func fetchScaleStatus(siteID: Int64, completion: @escaping (Result<ShippingScaleStatus, Error>) -> Void)
}

/// Shipping Labels Remote Endpoints.
public final class ShippingLabelRemote: Remote, ShippingLabelRemoteProtocol {
    /// Loads shipping labels and settings for an order.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the order.
    ///   - orderID: Remote ID of the order that owns the shipping labels.
    ///   - completion: Closure to be executed upon completion.
    public func loadShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<OrderShippingLabelListResponse, Error>) -> Void) {
        let path = "\(Path.shippingLabels)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path)
        let mapper = OrderShippingLabelListMapper(siteID: siteID, orderID: orderID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Generates shipping label data for printing.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping labels.
    ///   - shippingLabelIDs: Remote IDs of the shipping labels.
    ///   - paperSize: Paper size option (current options are "label", "legal", and "letter").
    ///   - completion: Closure to be executed upon completion.
    public func printShippingLabel(siteID: Int64,
                                   shippingLabelIDs: [Int64],
                                   paperSize: ShippingLabelPaperSize,
                                   completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.paperSize: paperSize.rawValue,
            ParameterKey.labelIDCSV: shippingLabelIDs.map(String.init).joined(separator: ","),
            ParameterKey.captionCSV: "",
            ParameterKey.json: "true" // `json=true` is necessary, otherwise it results in 500 error "no_response_body".
        ]
        let path = "\(Path.shippingLabels)/print"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ShippingLabelPrintDataMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Requests a refund for a shipping label.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - orderID: Remote ID of the order that owns the shipping labels.
    ///   - shippingLabelID: Remote ID of the shipping label.
    ///   - completion: Closure to be executed upon completion.
    public func refundShippingLabel(siteID: Int64, orderID: Int64, shippingLabelID: Int64, completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        let path = "\(Path.shippingLabels)/\(orderID)/\(shippingLabelID)/refund"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path)
        let mapper = ShippingLabelRefundMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Address validation for a shipping address.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - address: The address that should be verified.
    ///   - completion: Closure to be executed upon completion.
    public func addressValidation(siteID: Int64,
                                  address: ShippingLabelAddressVerification,
                                  completion: @escaping (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void) {
        do {
            let parameters = try address.toDictionary()
            let path = "\(Path.normalizeAddress)"
            let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = ShippingLabelAddressValidationSuccessMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Requests all the details for the packages (custom and predefined).
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the shipping label.
    ///   - completion: Closure to be executed upon completion.
    public func packagesDetails(siteID: Int64,
                                completion: @escaping (Result<ShippingLabelPackagesResponse, Error>) -> Void) {
        let path = Path.packages
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ShippingLabelPackagesMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Creates a new custom package or activates a service package.
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
            let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = SuccessDataResultMapper()
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Loads carriers and their rates.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: ID of the order.
    ///   - originAddress: the origin address entity.
    ///   - destinationAddress: the destination address entity.
    ///   - packages: The package previously selected with all their data.
    ///   - completion: Closure to be executed upon completion.
    public func loadCarriersAndRates(siteID: Int64,
                                     orderID: Int64,
                                     originAddress: ShippingLabelAddress,
                                     destinationAddress: ShippingLabelAddress,
                                     packages: [ShippingLabelPackageSelected],
                                     completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: try packages.map { try $0.toDictionary() }
            ]
            let path = "\(Path.shippingLabels)/\(orderID)/rates"
            let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = ShippingLabelCarriersAndRatesMapper()
            enqueue(request, mapper: mapper, completion: completion)
        }
        catch {
            completion(.failure(error))
        }
    }

    /// Loads account-level shipping label settings for a store.
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - completion: Closure to be executed upon completion.
    public func loadShippingLabelAccountSettings(siteID: Int64, completion: @escaping (Result<ShippingLabelAccountSettings, Error>) -> Void) {
        let path = Path.accountSettings
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path)
        let mapper = ShippingLabelAccountSettingsMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates account-level shipping label settings for a store.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - settings: The shipping label account settings to update remotely.
    ///     - completion: Closure to be executed upon completion.
    public func updateShippingLabelAccountSettings(siteID: Int64, settings: ShippingLabelAccountSettings, completion: @escaping (Result<Bool, Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.selectedPaymentMethodID: settings.selectedPaymentMethodID,
            ParameterKey.emailReceipts: settings.isEmailReceiptsEnabled,
            ParameterKey.paperSize: settings.paperSize.rawValue
        ]
        let path = Path.accountSettings
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path, parameters: parameters)
        let mapper = SuccessDataResultMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Checks eligibility for shipping label creation.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - orderID: Remote ID of the order that owns the shipping labels.
    ///     - canCreatePaymentMethod: Whether the client supports creating new payment methods.
    ///     - canCreateCustomsForm: Whether the client supports creating customs forms.
    ///     - canCreatePackage: Whether the client supports creating packages.
    ///     - completion: Closure to be executed upon completion.
    public func checkCreationEligibility(siteID: Int64,
                                         orderID: Int64,
                                         canCreatePaymentMethod: Bool,
                                         canCreateCustomsForm: Bool,
                                         canCreatePackage: Bool,
                                         completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void) {
        let parameters = [
            ParameterKey.canCreatePaymentMethod: canCreatePaymentMethod,
            ParameterKey.canCreateCustomsForm: canCreateCustomsForm,
            ParameterKey.canCreatePackage: canCreatePackage
        ]
        let path = "\(Path.shippingLabels)/\(orderID)/creation_eligibility"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ShippingLabelCreationEligibilityMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Initiates a shipping label purchase.
    ///
    /// This request returns the label purchase data, including a `PURCHASE_IN_PROGRESS` status.
    /// After initiating the purchase, we must poll the backend for the updated label status (successful purchase or error).
    /// - Parameters:
    ///   - siteID: Remote ID of the site.
    ///   - orderID: Remote ID of the order that owns the shipping labels.
    ///   - originAddress: the origin address entity.
    ///   - destinationAddress: the destination address entity.
    ///   - packages: The package previously selected with all their data.
    ///   - emailCustomerReceipt: Whether to email an order receipt to the customer.
    ///   - completion: Closure to be executed upon completion.
    public func purchaseShippingLabel(siteID: Int64,
                                      orderID: Int64,
                                      originAddress: ShippingLabelAddress,
                                      destinationAddress: ShippingLabelAddress,
                                      packages: [ShippingLabelPackagePurchase],
                                      emailCustomerReceipt: Bool,
                                      completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {
        do {
            let parameters: [String: Any] = [
                ParameterKey.async: true,
                ParameterKey.originAddress: try originAddress.toDictionary(),
                ParameterKey.destinationAddress: try destinationAddress.toDictionary(),
                ParameterKey.packages: try packages.map { try $0.toDictionary() },
                ParameterKey.emailReceipt: emailCustomerReceipt
            ]
            let path = "\(Path.shippingLabels)/\(orderID)"
            let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .post, siteID: siteID, path: path, parameters: parameters)
            let mapper = ShippingLabelPurchaseMapper(siteID: siteID, orderID: orderID)
            enqueue(request, mapper: mapper, completion: completion)
        }
        catch {
            completion(.failure(error))
        }
    }

    /// Checks the shipping label status
    ///
    /// Used after purchasing a shipping label, to check for errors or confirm a successful purchase.
    /// This is used instead of `loadShippingLabels` to ensure up-to-date (non-cached) results.
    /// - Parameters:
    ///     - siteID: Remote ID of the site.
    ///     - orderID: Remote ID of the order that owns the shipping labels.
    ///     - labelIDs: Remote ID(s) of the label(s) to check the status of.
    ///     - completion: Closure to be executed upon completion.
    public func checkLabelStatus(siteID: Int64,
                                    orderID: Int64,
                                    labelIDs: [Int64],
                                    completion: @escaping (Result<[ShippingLabelStatusPollingResponse], Error>) -> Void) {
        let labelIDs = labelIDs.map(String.init).joined(separator: ",")
        let path = "\(Path.shippingLabels)/\(orderID)/\(labelIDs)"
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: path)
        let mapper = ShippingLabelStatusMapper(siteID: siteID, orderID: orderID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetches the scale data including weight most recently reported.
    ///
    public func fetchScaleStatus(siteID: Int64,
                               completion: @escaping(Result<ShippingScaleStatus, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .wcConnectV1, method: .get, siteID: siteID, path: Path.scaleStatus)

        let mapper = ShippingScaleStatusMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: Constant
private extension ShippingLabelRemote {
    enum Path {
        static let shippingLabels = "label"
        static let normalizeAddress = "normalize-address"
        static let packages = "packages"
        static let accountSettings = "account/settings"
        static let scaleStatus = "scale"
    }

    enum ParameterKey {
        static let paperSize = "paper_size"
        static let labelIDCSV = "label_id_csv"
        static let captionCSV = "caption_csv"
        static let json = "json"
        static let custom = "custom"
        static let predefined = "predefined"
        static let canCreatePaymentMethod = "can_create_payment_method"
        static let canCreateCustomsForm = "can_create_customs_form"
        static let canCreatePackage = "can_create_package"
        static let originAddress = "origin"
        static let destinationAddress = "destination"
        static let packages = "packages"
        static let selectedPaymentMethodID = "selected_payment_method_id"
        static let emailReceipts = "email_receipts"
        static let emailReceipt = "email_receipt"
        static let async = "async"
    }
}

// MARK: Errors {
extension ShippingLabelRemote {
    enum ShippingLabelError: Error {
        case missingPackage
    }
}
