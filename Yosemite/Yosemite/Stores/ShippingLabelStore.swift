import Foundation
import Networking
import Storage

/// Implements `ShippingLabelAction` actions
///
public final class ShippingLabelStore: Store {
    private let remote: ShippingLabelRemoteProtocol

    /// Shared private StorageType for use during then entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ShippingLabelRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: ShippingLabelRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ShippingLabelAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? ShippingLabelAction else {
            assertionFailure("ShippingLabelStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeShippingLabels(let siteID, let orderID, let completion):
            synchronizeShippingLabels(siteID: siteID, orderID: orderID, completion: completion)
        case .printShippingLabel(let siteID, let shippingLabelIDs, let paperSize, let completion):
            printShippingLabel(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize, completion: completion)
        case .refundShippingLabel(let shippingLabel, let completion):
            refundShippingLabel(shippingLabel: shippingLabel,
                                completion: completion)
        case .loadShippingLabelSettings(let shippingLabel, let completion):
            loadShippingLabelSettings(shippingLabel: shippingLabel, completion: completion)
        case .validateAddress(let siteID, let address, let completion):
            validateAddress(siteID: siteID, address: address, completion: completion)
        case .packagesDetails(let siteID, let completion):
            packagesDetails(siteID: siteID, completion: completion)
        case .checkCreationEligibility(let siteID, let orderID, let canCreatePaymentMethod, let canCreateCustomsForm, let canCreatePackage, let onCompletion):
            checkCreationEligibility(siteID: siteID,
                                     orderID: orderID,
                                     canCreatePaymentMethod: canCreatePaymentMethod,
                                     canCreateCustomsForm: canCreateCustomsForm,
                                     canCreatePackage: canCreatePackage,
                                     onCompletion: onCompletion)
        case .createPackage(let siteID, let customPackage, let predefinedOption, let completion):
            createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption, completion: completion)
        case .loadCarriersAndRates(let siteID, let orderID, let originAddress, let destinationAddress, let packages, let completion):
            loadCarriersAndRates(siteID: siteID,
                                 orderID: orderID,
                                 originAddress: originAddress,
                                 destinationAddress: destinationAddress,
                                 packages: packages,
                                 completion: completion)
        case .synchronizeShippingLabelAccountSettings(let siteID, let completion):
            synchronizeShippingLabelAccountSettings(siteID: siteID, completion: completion)
        case .updateShippingLabelAccountSettings(let siteID, let settings, let completion):
            updateShippingLabelAccountSettings(siteID: siteID, settings: settings, completion: completion)
        case .purchaseShippingLabel(let siteID, let orderID, let originAddress, let destinationAddress, let packages, let emailCustomerReceipt, let completion):
            purchaseShippingLabel(siteID: siteID,
                                  orderID: orderID,
                                  originAddress: originAddress,
                                  destinationAddress: destinationAddress,
                                  packages: packages,
                                  emailCustomerReceipt: emailCustomerReceipt,
                                  completion: completion)
        }
    }
}

private extension ShippingLabelStore {
    func synchronizeShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadShippingLabels(siteID: siteID, orderID: orderID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.upsertShippingLabelsAndSettingsInBackground(siteID: siteID,
                                                                 orderID: orderID,
                                                                 shippingLabels: response.shippingLabels,
                                                                 settings: response.settings) {
                    completion(.success(()))
                }
            }
        }
    }

    func printShippingLabel(siteID: Int64,
                            shippingLabelIDs: [Int64],
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        remote.printShippingLabel(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize, completion: completion)
    }

    func refundShippingLabel(shippingLabel: ShippingLabel,
                             completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        remote.refundShippingLabel(siteID: shippingLabel.siteID,
                                   orderID: shippingLabel.orderID,
                                   shippingLabelID: shippingLabel.shippingLabelID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let refund):
                self.upsertShippingLabelRefundInBackground(shippingLabel: shippingLabel, refund: refund) {
                    completion(.success(refund))
                }
            }
        }
    }

    func loadShippingLabelSettings(shippingLabel: ShippingLabel, completion: (ShippingLabelSettings?) -> Void) {
        completion(storageManager.viewStorage.loadShippingLabelSettings(siteID: shippingLabel.siteID, orderID: shippingLabel.orderID)?.toReadOnly())
    }

    func validateAddress(siteID: Int64,
                         address: ShippingLabelAddressVerification,
                         completion: @escaping (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void) {
        remote.addressValidation(siteID: siteID, address: address, completion: completion)
    }

    func packagesDetails(siteID: Int64,
                         completion: @escaping (Result<ShippingLabelPackagesResponse, Error>) -> Void) {
        remote.packagesDetails(siteID: siteID, completion: completion)
    }

    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  canCreatePaymentMethod: Bool,
                                  canCreateCustomsForm: Bool,
                                  canCreatePackage: Bool,
                                  onCompletion: @escaping (_ isEligible: Bool) -> Void) {
        remote.checkCreationEligibility(siteID: siteID,
                                        orderID: orderID,
                                        canCreatePaymentMethod: canCreatePaymentMethod,
                                        canCreateCustomsForm: canCreateCustomsForm,
                                        canCreatePackage: canCreatePackage) { result in
            switch result {
            case .success(let eligibility):
                if !eligibility.isEligible {
                    if let reason = eligibility.reason {
                        DDLogError("Order \(orderID) not eligible for shipping label creation: \(reason)")
                    } else {
                        DDLogError("Order \(orderID) not eligible for shipping label creation")
                    }
                }
                onCompletion(eligibility.isEligible)
            case .failure(let error):
                if error as? DotcomError == .noRestRoute {
                    DDLogError("⚠️ Endpoint for shipping label creation eligibility is unreachable for order: \(orderID). WC Shipping plugin may be missing.")
                } else {
                    DDLogError("⛔️ Error checking shipping label creation eligibility for order \(orderID): \(error)")
                }
                onCompletion(false)
            }
        }
    }

    func createPackage(siteID: Int64,
                       customPackage: ShippingLabelCustomPackage?,
                       predefinedOption: ShippingLabelPredefinedOption?,
                       completion: @escaping (Result<Bool, PackageCreationError>) -> Void) {
        remote.createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption) { result in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure(let error):
                completion(.failure(PackageCreationError(error: error)))
            }
        }
    }

    func loadCarriersAndRates(siteID: Int64,
                              orderID: Int64,
                              originAddress: ShippingLabelAddress,
                              destinationAddress: ShippingLabelAddress,
                              packages: [ShippingLabelPackageSelected],
                              completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        remote.loadCarriersAndRates(siteID: siteID,
                                    orderID: orderID,
                                    originAddress: originAddress,
                                    destinationAddress: destinationAddress,
                                    packages: packages,
                                    completion: completion)
    }

    func synchronizeShippingLabelAccountSettings(siteID: Int64,
                                                 completion: @escaping (Result<ShippingLabelAccountSettings, Error>) -> Void) {
        remote.loadShippingLabelAccountSettings(siteID: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let settings):
                self.upsertShippingLabelAccountSettingsInBackground(siteID: siteID, accountSettings: settings) {
                    completion(.success(settings))
                }
            }
        }
    }

    func updateShippingLabelAccountSettings(siteID: Int64,
                                            settings: ShippingLabelAccountSettings,
                                            completion: @escaping (Result<Bool, Error>) -> Void) {
        remote.updateShippingLabelAccountSettings(siteID: siteID, settings: settings) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let success):
                self.upsertShippingLabelAccountSettingsInBackground(siteID: siteID, accountSettings: settings) {
                    completion(.success(success))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackagePurchase],
                               emailCustomerReceipt: Bool,
                               completion: @escaping (Result<[ShippingLabel], Error>) -> Void) {
        var labelPurchaseIDs: [Int64] = []

        // Make the initial purchase request.
        remote.purchaseShippingLabel(siteID: siteID,
                                     orderID: orderID,
                                     originAddress: originAddress,
                                     destinationAddress: destinationAddress,
                                     packages: packages,
                                     emailCustomerReceipt: emailCustomerReceipt) { result in
            switch result {
            case .success(let labelPurchases):
                // Save the IDs of label purchases in the response so we can poll the backend for their status.
                for label in labelPurchases {
                    labelPurchaseIDs.append(label.shippingLabelID)
                }

                // Wait for 2 seconds (give the backend time to process the purchase)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self = self else { return }

                    // Poll the status of the label purchases from the response above
                    // with a delay of 1 second each time, with a maximum of 3 retries for failed requests.
                    self.pollLabelStatus(withDelayInSeconds: 1.0,
                                         maxErrorRetries: 3,
                                         siteID: siteID,
                                         orderID: orderID,
                                         labelIDs: labelPurchaseIDs,
                                         completion: completion)
                }
            case .failure(let error):
                DDLogError("⛔️ Error purchasing shipping label for order \(orderID): \(error)")
                completion(.failure(error))
            }
        }
    }
}

private extension ShippingLabelStore {
    /// Updates/inserts the specified readonly shipping label & settings entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertShippingLabelsAndSettingsInBackground(siteID: Int64,
                                                     orderID: Int64,
                                                     shippingLabels: [ShippingLabel],
                                                     settings: ShippingLabelSettings,
                                                     onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            guard let order = derivedStorage.loadOrder(siteID: siteID, orderID: orderID) else {
                return
            }
            guard shippingLabels.isEmpty == false else {
                return
            }
            self.upsertShippingLabels(siteID: siteID, orderID: orderID, shippingLabels: shippingLabels, storageOrder: order)
            self.upsertShippingLabelSettings(siteID: siteID, orderID: orderID, settings: settings, storageOrder: order)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly shipping label refund for a shipping label *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertShippingLabelRefundInBackground(shippingLabel: ShippingLabel,
                                               refund: ShippingLabelRefund,
                                               onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            // If a shipping label does not exist in storage, skip upserting the refund in storage.
            guard let shippingLabel = derivedStorage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                       orderID: shippingLabel.orderID,
                                                                       shippingLabelID: shippingLabel.shippingLabelID) else {
                return
            }
            self.update(shippingLabel: shippingLabel, withRefund: refund)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabel entities in the current thread.
    func upsertShippingLabels(siteID: Int64, orderID: Int64, shippingLabels: [ShippingLabel], storageOrder: StorageOrder) {
        let derivedStorage = sharedDerivedStorage

        for shippingLabel in shippingLabels {
            let storageShippingLabel = derivedStorage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                        orderID: shippingLabel.orderID,
                                                                        shippingLabelID: shippingLabel.shippingLabelID) ??
                derivedStorage.insertNewObject(ofType: Storage.ShippingLabel.self)
            storageShippingLabel.update(with: shippingLabel)
            storageShippingLabel.order = storageOrder

            update(shippingLabel: storageShippingLabel, withRefund: shippingLabel.refund)

            let originAddress = storageShippingLabel.originAddress ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            originAddress.update(with: shippingLabel.originAddress)
            storageShippingLabel.originAddress = originAddress

            let destinationAddress = storageShippingLabel.destinationAddress ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            destinationAddress.update(with: shippingLabel.destinationAddress)
            storageShippingLabel.destinationAddress = destinationAddress
        }

        // Now, remove any objects that exist in storage but not in shippingLabels
        let shippingLabelIDs = shippingLabels.map(\.shippingLabelID)
        derivedStorage.loadAllShippingLabels(siteID: siteID, orderID: orderID).filter {
            !shippingLabelIDs.contains($0.shippingLabelID)
        }.forEach {
            derivedStorage.deleteObject($0)
        }
    }

    func update(shippingLabel storageShippingLabel: StorageShippingLabel, withRefund refund: ShippingLabelRefund?) {
        let derivedStorage = sharedDerivedStorage
        if let refund = refund {
            let storageRefund = storageShippingLabel.refund ?? derivedStorage.insertNewObject(ofType: Storage.ShippingLabelRefund.self)
            storageRefund.update(with: refund)
            storageShippingLabel.refund = storageRefund
        } else {
            storageShippingLabel.refund = nil
        }
    }

    /// Updates/inserts the specified readonly ShippingLabelSettings entity in the current thread.
    func upsertShippingLabelSettings(siteID: Int64, orderID: Int64, settings: ShippingLabelSettings, storageOrder: StorageOrder) {
        let derivedStorage = sharedDerivedStorage
        let storageSettings = derivedStorage.loadShippingLabelSettings(siteID: siteID, orderID: orderID) ??
            derivedStorage.insertNewObject(ofType: Storage.ShippingLabelSettings.self)
        storageSettings.update(with: settings)
        storageSettings.order = storageOrder
    }

    /// Updates/inserts the specified readonly shipping label account settings entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertShippingLabelAccountSettingsInBackground(siteID: Int64,
                                                        accountSettings: ShippingLabelAccountSettings,
                                                        onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertShippingLabelAccountSettings(siteID: siteID, accountSettings: accountSettings)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabelAccountSettings entity in the current thread.
    ///
    func upsertShippingLabelAccountSettings(siteID: Int64, accountSettings: ShippingLabelAccountSettings) {
        let derivedStorage = sharedDerivedStorage
        let storageAccountSettings = derivedStorage.loadShippingLabelAccountSettings(siteID: siteID) ??
            derivedStorage.insertNewObject(ofType: Storage.ShippingLabelAccountSettings.self)
        storageAccountSettings.update(with: accountSettings)
        handleShippingLabelPaymentMethods(accountSettings, storageAccountSettings, derivedStorage)
    }

    /// Updates/inserts the ShippingLabelPaymentMethod items from the provided account settings.
    ///
    func handleShippingLabelPaymentMethods(_ readOnlyAccountSettings: Networking.ShippingLabelAccountSettings,
                                           _ storageAccountSettings: Storage.ShippingLabelAccountSettings,
                                           _ storage: StorageType) {
        // Remove all previous payment methods
        storageAccountSettings.paymentMethods?.removeAll()

        // Insert the payment methods from the read-only account settings
        for paymentMethod in readOnlyAccountSettings.paymentMethods {
            let newStoragePaymentMethod = storage.insertNewObject(ofType: Storage.ShippingLabelPaymentMethod.self)
            newStoragePaymentMethod.update(with: paymentMethod)
            storageAccountSettings.addToPaymentMethods(newStoragePaymentMethod)
        }
    }

    /// Polls the status of the purchases for labels with given IDs,
    /// with a delay of 1 second each time, and a maximum of 3 retries for failed requests.
    func pollLabelStatus(withDelayInSeconds delay: Double,
                         maxErrorRetries: Int64,
                         siteID: Int64,
                         orderID: Int64,
                         labelIDs: [Int64],
                         completion: @escaping (Result<[ShippingLabel], Error>) -> Void) {
        remote.checkLabelStatus(siteID: siteID, orderID: orderID, labelIDs: labelIDs) { [weak self] result in
            switch result {
            case .success(let labelStatusResponse):
                // If all labels have PURCHASED status, stop polling
                if labelStatusResponse.allSatisfy({ $0.status == .purchased }) {
                    let labels = labelStatusResponse.compactMap { $0.getPurchasedLabel() }
                    completion(.success(labels))
                }

                // If any label has PURCHASE_ERROR status, return error and stop polling
                else if labelStatusResponse.contains(where: { $0.status == .purchaseError }) {
                    DDLogError("⛔️ Error purchasing shipping label for order \(orderID)")
                    completion(.failure(LabelPurchaseError.purchaseErrorStatus))
                }

                // If no errors but status is not PURCHASED for all labels, poll again after delay
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.pollLabelStatus(withDelayInSeconds: delay,
                                              maxErrorRetries: maxErrorRetries,
                                              siteID: siteID,
                                              orderID: orderID,
                                              labelIDs: labelIDs,
                                              completion: completion)
                    }
                }

            case .failure(let error):
                // If there are retries left, poll again after delay
                if maxErrorRetries > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.pollLabelStatus(withDelayInSeconds: delay,
                                              maxErrorRetries: maxErrorRetries - 1,
                                              siteID: siteID,
                                              orderID: orderID,
                                              labelIDs: labelIDs,
                                              completion: completion)
                    }
                }

                // If there are no retries left, stop polling
                else {
                    DDLogError("⛔️ Error checking shipping label status for order \(orderID): \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}

/// Represents errors that can be returned when checking shipping label purchase status
public enum LabelPurchaseError: Error {
    /// API returns a `PURCHASE_ERROR` status for a label
    case purchaseErrorStatus
    /// Label purchase not complete after polling the backend
    case purchaseIncomplete
}

/// An error that occurs while creating a package.
///
/// - duplicateCustomPackageNames: The new custom package names are not unique.
/// - duplicatePackageNames: At least one of the new custom packages has the same name as existing packages.
/// - duplicatePredefinedPackageNames: The new predefined package names are not unique.
/// - duplicateNamesByCarrier: At least one of the new predefined packages has the same name as existing packages.
/// - unknown: other error cases.
///
public enum PackageCreationError: Error, Equatable {
    case duplicateCustomPackageNames
    case duplicatePackageNames
    case duplicatePredefinedPackageNames
    case duplicateNamesByCarrier
    case unknown(error: AnyError)

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown(error: error.toAnyError)
            return
        }
        switch dotcomError {
        case .unknown(let code, _):
            guard let errorCode = ErrorCode(rawValue: code) else {
                self = .unknown(error: dotcomError.toAnyError)
                return
            }
            self = errorCode.error
        default:
            self = .unknown(error: dotcomError.toAnyError)
        }
    }

    private enum ErrorCode: String {
        case duplicateCustomPackageNames = "duplicate_custom_package_names"
        case duplicatePackageNames = "duplicate_custom_package_names_of_existing_packages"
        case duplicatePredefinedPackageNames = "duplicate_predefined_package_names"
        case duplicateNamesByCarrier = "duplicate_predefined_package_names_of_existing_packages"

        var error: PackageCreationError {
            switch self {
            case .duplicateCustomPackageNames:
                return .duplicateCustomPackageNames
            case .duplicatePredefinedPackageNames:
                return .duplicatePredefinedPackageNames
            case .duplicatePackageNames:
                return .duplicatePackageNames
            case .duplicateNamesByCarrier:
                return .duplicateNamesByCarrier
            }
        }
    }
}
