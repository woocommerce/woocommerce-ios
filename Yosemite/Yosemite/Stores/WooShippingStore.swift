import Foundation
import Networking
import Storage

/// Implements `WooShippingAction` actions
///
public final class WooShippingStore: Store {
    private let remote: WooShippingRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = WooShippingRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: WooShippingRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WooShippingAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? WooShippingAction else {
            assertionFailure("WooShippingStore received an unsupported action")
            return
        }

        switch action {
        case .createPackage(let siteID, let customPackage, let predefinedOption, let completion):
            createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption, completion: completion)
        case .deletePackage(let siteID, let packageID, let completion):
            deletePackage(siteID: siteID, packageID: packageID, completion: completion)
        case .loadLabelRates(let siteID, let orderID, let originAddress, let destinationAddress, let packages, let completion):
            loadLabelRates(siteID: siteID,
                           orderID: orderID,
                           originAddress: originAddress,
                           destinationAddress: destinationAddress,
                           packages: packages,
                           completion: completion)
        case .loadPackages(let siteID, completion: let completion):
            loadPackages(siteID: siteID, completion: completion)
        case .loadAccountSettings(let siteID, completion: let completion):
            loadAccountSettings(siteID: siteID, completion: completion)
        case let .purchaseShippingLabel(siteID,
                                        orderID,
                                        originAddress,
                                        destinationAddress,
                                        package,
                                        backendProcessingDelay,
                                        pollingDelay,
                                        pollingMaximumRetries,
                                        completion):
            purchaseShippingLabel(siteID: siteID,
                                  orderID: orderID,
                                  originAddress: originAddress,
                                  destinationAddress: destinationAddress,
                                  package: package,
                                  backendProcessingDelay: backendProcessingDelay,
                                  pollingDelay: pollingDelay,
                                  pollingMaximumRetries: pollingMaximumRetries,
                                  completion: completion)
        case let .printLabel(siteID, labelIDs, paperSize, completion):
            printLabel(siteID: siteID, labelIDs: labelIDs, paperSize: paperSize, completion: completion)
        case .loadOriginAddresses(let siteID, let completion):
            loadOriginAddresses(siteID: siteID, completion: completion)
        case let .validateAddress(siteID, address, completion):
            validateAddress(siteID: siteID, address: address, completion: completion)
        case let .updateOriginAddress(siteID, address, isVerified, completion):
            updateOriginAddress(siteID: siteID, address: address, isVerified: isVerified, completion: completion)
        }
    }
}

private extension WooShippingStore {
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void) {
        remote.createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption) { [weak self] result in
            switch result {
            case .success(let packages):
                self?.upsertCreatePackagesResponseInBackground(readOnlyPackages: packages, siteID: siteID, onCompletion: {
                    completion(.success(packages))
                })
            case .failure(let error):
                completion(.failure(PackageCreationError(error: error)))
            }
        }
    }

    func deletePackage(siteID: Int64,
                       packageID: String,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        remote.deletePackage(siteID: siteID, packageID: packageID) { [weak self] result in
            switch result {
            case .success(let packages):
                self?.upsertCreatePackagesResponseInBackground(readOnlyPackages: packages, siteID: siteID, onCompletion: {
                    completion(.success(packages))
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: ShippingLabelAddress,
                        destinationAddress: ShippingLabelAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        remote.loadLabelRates(siteID: siteID,
                              orderID: orderID,
                              originAddress: originAddress,
                              destinationAddress: destinationAddress,
                              packages: packages,
                              completion: completion)
    }

    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, WooShippingLoadPackagesError>) -> Void) {
        remote.loadPackages(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let packages):
                self?.upsertPackagesResponseInBackground(readOnlyPackages: packages, siteID: siteID) {
                    completion(.success(packages))
                }
            case .failure(let error):
                completion(.failure(WooShippingLoadPackagesError.loadingFailed(error: error)))
            }
        }
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(siteID: siteID, completion: completion)
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               backendProcessingDelay: TimeInterval,
                               pollingDelay: TimeInterval,
                               pollingMaximumRetries: Int64,
                               completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        // Make the initial purchase request.
        remote.purchaseShippingLabel(siteID: siteID,
                                     orderID: orderID,
                                     originAddress: originAddress,
                                     destinationAddress: destinationAddress,
                                     package: package) { result in
            switch result {
            case .success(let labelPurchases):
                // Purchase endpoint returns an array of labels, but the polling endpoint only takes a single label at a time.
                // Since we only expect to purchase one label at a time, we get the first label from the response.
                guard let labelID = labelPurchases.first?.shippingLabelID else {
                    DDLogError("⛔️ No labels in Woo Shipping label purchase response")
                    return completion(.failure(WooShippingLabelPurchaseError.purchaseMissingLabels))
                }

                // Wait to give the backend time to process the purchase
                DispatchQueue.main.asyncAfter(deadline: .now() + backendProcessingDelay) { [weak self] in
                    guard let self else { return }

                    // Poll the status of the label purchase from the response above
                    pollLabelStatus(withDelayInSeconds: pollingDelay,
                                    maxErrorRetries: pollingMaximumRetries,
                                    siteID: siteID,
                                    orderID: orderID,
                                    labelID: labelID,
                                    completion: completion)
                }
            case .failure(let error):
                DDLogError("⛔️ Error purchasing shipping label for order \(orderID): \(error)")
                completion(.failure(error))
            }
        }
    }

    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: ShippingLabelPaperSize,
                    completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        remote.printLabel(siteID: siteID, labelIDs: labelIDs, paperSize: paperSize, completion: completion)
    }

    func loadOriginAddresses(siteID: Int64,
                             completion: @escaping (Result<[WooShippingOriginAddress], Error>) -> Void) {
        remote.loadOriginAddresses(siteID: siteID, completion: completion)
    }
}

// MARK: Helpers
private extension WooShippingStore {
    /// Polls the status of the purchase for the provided label ID,
    /// with a delay of 1 second each time, and a maximum of 3 retries for failed requests.
    func pollLabelStatus(withDelayInSeconds delay: Double,
                         maxErrorRetries: Int64,
                         siteID: Int64,
                         orderID: Int64,
                         labelID: Int64,
                         completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        remote.checkLabelStatus(siteID: siteID, orderID: orderID, labelID: labelID) { [weak self] result in
            switch result {
            case .success(let labelStatusResponse):
                // If label has PURCHASED status, stop polling
                if labelStatusResponse.status == .purchased,
                   let label = labelStatusResponse.getPurchasedLabel() {
                    completion(.success(label))
                }

                // If label has PURCHASE_ERROR status, return error and stop polling
                else if labelStatusResponse.status == .purchaseError {
                    DDLogError("⛔️ Error purchasing shipping label for order \(orderID)")
                    completion(.failure(WooShippingLabelPurchaseError.purchaseErrorStatus))
                }

                // If no error but status is not PURCHASED, poll again after delay
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.pollLabelStatus(withDelayInSeconds: delay,
                                              maxErrorRetries: maxErrorRetries,
                                              siteID: siteID,
                                              orderID: orderID,
                                              labelID: labelID,
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
                                              labelID: labelID,
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

    func validateAddress(siteID: Int64,
                         address: ShippingLabelAddress,
                         completion: @escaping (Result<WooShippingAddressValidationSuccess, Error>) -> Void) {
        remote.addressValidation(siteID: siteID, address: address, completion: completion)
    }

    func updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: @escaping (Result<WooShippingOriginAddressUpdate, Error>) -> Void) {
        remote.updateOriginAddress(siteID: siteID, address: address, isVerified: isVerified, completion: completion)
    }
}

// MARK: - Storage
private extension WooShippingStore {
    /// Updates (OR Inserts) the specified ReadOnly WooShippingPackagesResponse Entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertPackagesResponseInBackground(readOnlyPackages: Networking.WooShippingPackagesResponse,
                                            siteID: Int64,
                                            onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            upsertPackagesResponse(readOnlyPackages: readOnlyPackages, in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly WooShippingCreatePackageResponse Entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertCreatePackagesResponseInBackground(readOnlyPackages: Networking.WooShippingCreatePackageResponse,
                                                  siteID: Int64,
                                                  onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            upsertCreatePackageResponse(readOnlyPackages: readOnlyPackages, siteID: siteID, in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly `WooShippingPackagesResponse` Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyPackages: Remote `WooShippingPackagesResponse` to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertPackagesResponse(readOnlyPackages: Networking.WooShippingPackagesResponse, in storage: StorageType) {
        let storagePackages = storage.loadPackages(siteID: readOnlyPackages.siteID) ??
        storage.insertNewObject(ofType: Storage.WooShippingPackagesResponse.self)

        storagePackages.update(with: readOnlyPackages)
        handleAllPredefinedOptions(readOnlyPackages, storagePackages, storage)
        handleCustomPackages(readOnlyPackages.customPackages, storagePackages, storage)
        handleSavedPredefinedPackages(readOnlyPackages.savedPredefinedPackages, storagePackages, storage)
    }

    /// Updates (OR Inserts) the specified ReadOnly `WooShippingCreatePackageResponse` Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyPackages: Remote `WooShippingCreatePackageResponse` to be persisted.
    ///     - siteID: Site ID to be associated with the packages.
    ///     - storage: Where we should save all the things!
    ///
    func upsertCreatePackageResponse(readOnlyPackages: Networking.WooShippingCreatePackageResponse, siteID: Int64, in storage: StorageType) {
        let storagePackages = storage.loadPackages(siteID: siteID) ?? storage.insertNewObject(ofType: Storage.WooShippingPackagesResponse.self)
        storagePackages.siteID = siteID

        handleCustomPackages(readOnlyPackages.customPackages, storagePackages, storage)
        handleSavedPredefinedOptions(readOnlyPackages.predefinedOptions, storagePackages, storage)
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingPackagesResponse's allPredefinedOptions
    /// using the provided read-only WooShippingPackagesResponse's allPredefinedOptions
    ///
    func handleAllPredefinedOptions(_ readOnlyPackages: Networking.WooShippingPackagesResponse,
                                    _ storagePackages: Storage.WooShippingPackagesResponse,
                                    _ storage: StorageType) {
        // Remove all previous predefined options, they will be deleted as they have the `cascade` delete rule
        if let allPredefinedOptions = storagePackages.allPredefinedOptions {
            storagePackages.removeFromAllPredefinedOptions(allPredefinedOptions)
        }

        // Creates and adds `storageAllPredefinedOptions` from `readOnlyPackages.allPredefinedOptions`
        let storageAllPredefinedOptions = readOnlyPackages.allPredefinedOptions.map { readOnlyCarrierOptions -> Storage.WooShippingCarrierPredefinedOptions in
            let storageCarrierOptions = storage.insertNewObject(ofType: Storage.WooShippingCarrierPredefinedOptions.self)
            storageCarrierOptions.update(with: readOnlyCarrierOptions)
            handlePredefinedOptions(readOnlyCarrierOptions, storageCarrierOptions, storage)
            return storageCarrierOptions
        }
        storagePackages.addToAllPredefinedOptions(NSOrderedSet(array: storageAllPredefinedOptions))
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingCarrierPredefinedOptions's predefinedOptions
    /// using the provided read-only WooShippingCarrierPredefinedOptions's predefinedOptions
    func handlePredefinedOptions(_ readOnlyCarrierOptions: Networking.WooShippingCarrierPredefinedOptions,
                                 _ storageCarrierOptions: Storage.WooShippingCarrierPredefinedOptions,
                                 _ storage: StorageType) {
        // Remove all previous predefined options, they will be deleted as they have the `cascade` delete rule
        if let predefinedOptions = storageCarrierOptions.predefinedOptions {
            storageCarrierOptions.removeFromPredefinedOptions(predefinedOptions)
        }

        // Creates and adds `storagePredefinedOptions` from `readOnlyCarriers.predefinedOptions`
        let storagePredefinedOptions = readOnlyCarrierOptions.predefinedOptions.map { readOnlyOption -> Storage.WooShippingPredefinedOption in
            let storageOption = storage.insertNewObject(ofType: Storage.WooShippingPredefinedOption.self)
            storageOption.update(with: readOnlyOption)
            handlePredefinedPackages(readOnlyOption, storageOption, storage)
            return storageOption
        }
        storageCarrierOptions.addToPredefinedOptions(NSOrderedSet(array: storagePredefinedOptions))
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingPredefinedOption's predefinedPackages
    /// using the provided read-only WooShippingPredefinedOption's predefinedPackages
    func handlePredefinedPackages(_ readOnlyOption: Networking.WooShippingPredefinedOption,
                                  _ storageOption: Storage.WooShippingPredefinedOption,
                                  _ storage: StorageType) {
        // Remove all previous predefined packages, they will be deleted as they have the `cascade` delete rule
        if let predefinedPackages = storageOption.predefinedPackages {
            storageOption.removeFromPredefinedPackages(NSSet(set: predefinedPackages))
        }

        // Creates and adds `storagePredefinedPackages` from `readOnlyOption.predefinedPackages`
        let storagePredefinedPackages = readOnlyOption.predefinedPackages.map { readOnlyPackage -> Storage.WooShippingPredefinedPackage in
            let storagePackage = storage.insertNewObject(ofType: Storage.WooShippingPredefinedPackage.self)
            storagePackage.update(with: readOnlyPackage)
            return storagePackage
        }
        storageOption.addToPredefinedPackages(NSSet(array: storagePredefinedPackages))
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingPackagesResponse's customPackages
    /// using the provided read-only WooShippingCustomPackages
    ///
    func handleCustomPackages(_ readOnlyCustomPackages: [Networking.WooShippingCustomPackage],
                              _ storagePackages: Storage.WooShippingPackagesResponse,
                              _ storage: StorageType) {
        // Remove all previous custom packages, they will be deleted as they have the `cascade` delete rule
        if let customPackages = storagePackages.customPackages {
            storagePackages.removeFromCustomPackages(NSSet(set: customPackages))
        }

        // Creates and adds `storageCustomPackages` from `readOnlyPackages.customPackages`
        let storageCustomPackages = readOnlyCustomPackages.map { readOnlyPackage -> Storage.WooShippingCustomPackage in
            let storagePackage = storage.insertNewObject(ofType: Storage.WooShippingCustomPackage.self)
            storagePackage.update(with: readOnlyPackage)
            return storagePackage
        }
        storagePackages.addToCustomPackages(NSSet(array: storageCustomPackages))
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingPackagesResponse's savedPredefinedPackages
    /// using the provided read-only WooShippingPackagesResponse's savedPredefinedPackages
    ///
    func handleSavedPredefinedPackages(_ readOnlySavedPackages: [Networking.WooShippingSavedPredefinedPackage],
                                       _ storagePackages: Storage.WooShippingPackagesResponse,
                                       _ storage: StorageType) {
        // Remove all previous saved predefined packages, they will be deleted as they have the `cascade` delete rule
        if let savedPredefinedPackages = storagePackages.savedPredefinedPackages {
            storagePackages.removeFromSavedPredefinedPackages(NSSet(set: savedPredefinedPackages))
        }

        // Creates and adds `storageSavedPredefinedPackages` from `readOnlyPackages.savedPredefinedPackages`
        let storageSavedPredefinedPackages = readOnlySavedPackages.map { readOnlyPackage -> Storage.WooShippingSavedPredefinedPackage in
            let storagePackage = storage.insertNewObject(ofType: Storage.WooShippingSavedPredefinedPackage.self)
            storagePackage.update(with: readOnlyPackage)
            handlePredefinedPackage(readOnlyPackage, storagePackage, storage)
            return storagePackage
        }
        storagePackages.addToSavedPredefinedPackages(NSSet(array: storageSavedPredefinedPackages))
    }

    /// Updates, inserts, or prunes the provided Storage.WooShippingPackagesResponse's savedPredefinedPackages
    /// using the provided read-only WooShippingPredefinedSavedOptions
    ///
    func handleSavedPredefinedOptions(_ readOnlySavedOptions: [WooShippingPredefinedSavedOption],
                                      _ storagePackages: Storage.WooShippingPackagesResponse,
                                      _ storage: StorageType) {
        guard let storagePredefinedOptions: [StorageWooShippingCarrierPredefinedOptions] = storagePackages.allPredefinedOptions?.toArray() else {
            return
        }
        let readOnlyPredefinedOptions = storagePredefinedOptions.map({ $0.toReadOnly() })
        let savedPackages = transformSavedPredefinedOptions(readOnlySavedOptions, allPredefinedOptions: readOnlyPredefinedOptions)
        handleSavedPredefinedPackages(savedPackages, storagePackages, storage)
    }

    /// Transforms the provided `WooShippingPredefinedSavedOption`s into `WooShippingSavedPredefinedPackage`s to save in storage.
    ///
    func transformSavedPredefinedOptions(_ options: [WooShippingPredefinedSavedOption],
                                         allPredefinedOptions: [WooShippingCarrierPredefinedOptions]) -> [WooShippingSavedPredefinedPackage] {
        // helper function for creating jointIDs for easier checking if package should be used or not
        func jointID(carrierID: String, packageID: String) -> String {
            return "\(carrierID)-\(packageID)"
        }

        var jointIDs: [String] = []
        for option in options {
            for packageID in option.predefinedPackageIDs {
                jointIDs.append(jointID(carrierID: option.id, packageID: packageID))
            }
        }

        var allSavedOptions: [WooShippingSavedPredefinedPackage] = []

        // use predefined saved packages from list of all packages
        // since the response gives us IDs we need to get them manually from the list
        for carrier in allPredefinedOptions {
            let carrierID = carrier.carrierID
            for option in carrier.predefinedOptions {
                for package in option.predefinedPackages {
                    if jointIDs.contains(jointID(carrierID: carrierID, packageID: package.id)) {
                        allSavedOptions.append(WooShippingSavedPredefinedPackage(groupTitle: option.title, providerID: option.providerID, package: package))
                    }
                }
            }
        }

        return allSavedOptions
    }

    /// Updates or inserts the provided Storage.WooShippingSavedPredefinedPackage's package
    /// using the provided read-only WooShippingSavedPredefinedPackage's package
    ///
    func handlePredefinedPackage(_ readOnlySavedPackage: Networking.WooShippingSavedPredefinedPackage,
                                 _ storageSavedPackage: Storage.WooShippingSavedPredefinedPackage,
                                 _ storage: StorageType) {
        let predefinedPackage = storageSavedPackage.package ?? storage.insertNewObject(ofType: Storage.WooShippingPredefinedPackage.self)
        predefinedPackage.update(with: readOnlySavedPackage.package)
        storageSavedPackage.package = predefinedPackage
    }
}

/// Represents errors that can be returned when purchasing a shipping label
public enum WooShippingLabelPurchaseError: Error {
    /// API returns a `PURCHASE_ERROR` status for a label
    case purchaseErrorStatus
    /// No labels are returned by initial purchase request
    case purchaseMissingLabels
}

public enum WooShippingLoadPackagesError: Error, Equatable {
    case loadingInProgress
    case loadingFailed(error: Error)

    public static func ==(lhs: WooShippingLoadPackagesError, rhs: WooShippingLoadPackagesError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}
