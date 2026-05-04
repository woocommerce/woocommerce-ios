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
        case let .checkCreationEligibility(siteID, orderID, onCompletion):
            checkCreationEligibility(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
        case .createPackage(let siteID, let customPackage, let predefinedOption, let completion):
            createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption, completion: completion)
        case let .deletePackage(siteID, packageID, packageType, completion):
            deletePackage(siteID: siteID,
                          packageID: packageID,
                          packageType: packageType,
                          completion: completion)
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
        case let .updateAccountSettings(siteID, settings, completion):
            updateAccountSettings(siteID: siteID, settings: settings, completion: completion)
        case let .purchaseShippingLabel(siteID,
                                        orderID,
                                        originAddress,
                                        destinationAddress,
                                        package,
                                        markOrderComplete,
                                        backendProcessingDelay,
                                        pollingDelay,
                                        pollingMaximumRetries,
                                        completion):
            purchaseShippingLabel(siteID: siteID,
                                  orderID: orderID,
                                  originAddress: originAddress,
                                  destinationAddress: destinationAddress,
                                  package: package,
                                  markOrderComplete: markOrderComplete,
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
        case let .verifyDestinationAddress(siteID, orderID, completion):
            verifyDestinationAddress(siteID: siteID, orderID: orderID, completion: completion)
        case let .updateDestinationAddress(siteID, orderID, address, isVerified, completion):
            updateDestinationAddress(siteID: siteID, orderID: orderID, address: address, isVerified: isVerified, completion: completion)
        case let .loadConfig(siteID, orderID, completion):
            loadConfig(siteID: siteID, orderID: orderID, completion: completion)
        case let .syncShipments(siteID, orderID, completion):
            syncShipments(siteID: siteID, orderID: orderID, completion: completion)
        case let .updateShipment(siteID, orderID, shipmentToUpdate, completion):
            updateShipment(siteID: siteID,
                           orderID: orderID,
                           shipmentToUpdate: shipmentToUpdate,
                           completion: completion)
        case let .refundShippingLabel(shippingLabel, completion):
            refundShippingLabel(shippingLabel: shippingLabel, completion: completion)
        case let .acceptUPSTermsOfService(siteID, originAddress, completion):
            acceptUPSTermsOfService(siteID: siteID, originAddress: originAddress, completion: completion)
        case let .acceptFedExTermsOfService(siteID, completion):
            acceptFedExTermsOfService(siteID: siteID, completion: completion)
        }
    }
}

private extension WooShippingStore {
    /// Checks whether an order is eligible for shipping label creation.
    ///
    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  onCompletion: @escaping (_ isEligible: Bool) -> Void) {
        remote.checkCreationEligibility(siteID: siteID,
                                        orderID: orderID) { result in
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
                if case .noRestRoute = error as? DotcomError {
                    DDLogError("⚠️ Endpoint for shipping label creation eligibility is unreachable for order: \(orderID). WC Shipping plugin may be missing.")
                } else {
                    DDLogError("⛔️ Error checking shipping label creation eligibility for order \(orderID): \(error)")
                }
                onCompletion(false)
            }
        }
    }

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
                       packageType: WooShippingPackageType,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        remote.deletePackage(siteID: siteID, packageID: packageID, packageType: packageType) { [weak self] result in
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
                        originAddress: WooShippingAddress,
                        destinationAddress: WooShippingAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping ([ShippingLabelPackageSelected], Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        remote.loadLabelRates(siteID: siteID,
                              orderID: orderID,
                              originAddress: originAddress,
                              destinationAddress: destinationAddress,
                              packages: packages,
                              completion: { result in
            switch result {
            case let .success(rates) where rates.contains(where: \.hasInvalidDestinationNameRateError):
                completion(packages, .failure(WooShippingLoadLabelRatesError.invalidDestinationName))
            default:
                completion(packages, result)
            }
        })
    }

    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void) {
        remote.loadPackages(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let packages):
                self?.upsertPackagesResponseInBackground(readOnlyPackages: packages, siteID: siteID) {
                    completion(.success(packages))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(siteID: siteID, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let settings):
                upsertShippingLabelAccountSettingsInBackground(siteID: siteID, accountSettings: settings.accountSettings) {
                    completion(.success(settings))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func updateAccountSettings(siteID: Int64,
                               settings: ShippingLabelAccountSettings,
                               completion: @escaping (Result<Bool, Error>) -> Void) {
        remote.updateAccountSettings(siteID: siteID, settings: settings, completion: completion)
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: WooShippingAddress,
                               destinationAddress: WooShippingAddress,
                               package: WooShippingPackagePurchase,
                               markOrderComplete: Bool?,
                               backendProcessingDelay: TimeInterval,
                               pollingDelay: TimeInterval,
                               pollingMaximumRetries: Int64,
                               completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        // Make the initial purchase request.
        remote.purchaseShippingLabel(siteID: siteID,
                                     orderID: orderID,
                                     originAddress: originAddress,
                                     destinationAddress: destinationAddress,
                                     package: package,
                                     markOrderComplete: markOrderComplete) { result in
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
        remote.loadOriginAddresses(siteID: siteID, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let addresses):
                upsertOriginAddressesInBackground(siteID: siteID, originAddresses: addresses) {
                    completion(.success(addresses))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func refundShippingLabel(shippingLabel: ShippingLabel,
                             completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        remote.refundShippingLabel(siteID: shippingLabel.siteID,
                                   orderID: shippingLabel.orderID,
                                   shippingLabelID: shippingLabel.shippingLabelID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let refund):
                upsertShippingLabelRefundInBackground(shippingLabel: shippingLabel,
                                                      refund: refund) { updatedLabel in
                    completion(.success(updatedLabel))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func acceptUPSTermsOfService(siteID: Int64,
                                 originAddress: WooShippingAddress,
                                 completion: @escaping (Result<Bool, Error>) -> Void) {
        remote.acceptUPSTermsOfService(siteID: siteID, originAddress: originAddress, completion: completion)
    }

    func acceptFedExTermsOfService(siteID: Int64,
                                   completion: @escaping (Result<Bool, Error>) -> Void) {
        remote.acceptFedExTermsOfService(siteID: siteID, completion: completion)
    }

    func syncShipments(siteID: Int64,
                       orderID: Int64,
                       completion: @escaping (Result<[WooShippingShipment], Error>) -> Void) {
        remote.loadConfig(siteID: siteID, orderID: orderID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let config):
                let shipments = config.shipments
                upsertShipmentsInBackground(siteID: siteID,
                                            orderID: orderID,
                                            shipments: shipments) {
                    completion(.success(shipments))
                }
            }
        }
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
                    guard let self else {
                        return completion(.success(label))
                    }
                    insertPurchasedLabelInBackground(siteID: siteID, orderID: orderID, shippingLabel: label) {
                        completion(.success(label))
                    }
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
                         address: WooShippingAddress,
                         completion: @escaping (Result<WooShippingAddressValidationSuccess, Error>) -> Void) {
        remote.addressValidation(siteID: siteID, address: address, completion: completion)
    }

    func updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: @escaping (Result<WooShippingOriginAddressUpdate, Error>) -> Void) {
        remote.updateOriginAddress(siteID: siteID, address: address, isVerified: isVerified, completion: completion)
    }

    func verifyDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<WooShippingVerifyDestinationAddressSuccess, Error>) -> Void) {
        remote.verifyDestinationAddress(siteID: siteID, orderID: orderID, completion: completion)
    }

    func updateDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  address: WooShippingDestinationAddress,
                                  isVerified: Bool,
                                  completion: @escaping (Result<WooShippingDestinationAddressUpdate, Error>) -> Void) {
        remote.updateDestinationAddress(siteID: siteID, orderID: orderID, address: address, isVerified: isVerified) { [weak self] result in
            completion(result)

            guard let self, case .success = result else { return }
            setLastModifiedDateForOrder(siteID: siteID, orderID: orderID)
        }
    }

    func loadConfig(siteID: Int64,
                    orderID: Int64,
                    completion: @escaping (Result<WooShippingConfig, Error>) -> Void) {
        remote.loadConfig(siteID: siteID, orderID: orderID, completion: completion)
    }

    func updateShipment(siteID: Int64,
                        orderID: Int64,
                        shipmentToUpdate: WooShippingUpdateShipment,
                        completion: @escaping (Result<WooShippingShipments, Error>) -> Void) {
        remote.updateShipment(siteID: siteID, orderID: orderID, shipmentToUpdate: shipmentToUpdate) { [weak self] result in
            guard let self, let contents = try? result.get() else {
                return completion(result)
            }
            let shipments = contents.map { (index, items) in
                WooShippingShipment(siteID: siteID,
                                    orderID: orderID,
                                    index: index,
                                    items: items,
                                    shippingLabel: nil)
            }
            upsertShipmentsInBackground(siteID: siteID,
                                        orderID: orderID,
                                        shipments: shipments) {
                completion(.success(contents))
            }
        }
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

    /// Updates the specified origin addresses with the given refund *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertOriginAddressesInBackground(siteID: Int64,
                                           originAddresses: [WooShippingOriginAddress],
                                           onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            let storedOriginAddresses = storage.loadAllOriginAddresses(siteID: siteID)
            for address in originAddresses {
                let storageAddress = storedOriginAddresses.first(where: { $0.id == address.id }) ??
                storage.insertNewObject(ofType: Storage.WooShippingOriginAddress.self)
                storageAddress.update(with: address)
            }

            // Now, remove any objects that exist in storage but not in `originAddresses`
            let addressIDs = originAddresses.map(\.id)
            storedOriginAddresses.filter {
                !addressIDs.contains($0.id)
            }.forEach {
                storage.deleteObject($0)
            }
        }, completion: onCompletion, on: .main)
    }

    /// Updates the specified shipping label with the given refund *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertShippingLabelRefundInBackground(shippingLabel: ShippingLabel,
                                               refund: ShippingLabelRefund,
                                               onCompletion: @escaping (_ updatedLabel: ShippingLabel) -> Void) {
        storageManager.performAndSave ({ storage -> ShippingLabel in
            let storageShippingLabel = storage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                 orderID: shippingLabel.orderID,
                                                                 shippingLabelID: shippingLabel.shippingLabelID)
            guard let storageShippingLabel else {
                DDLogWarn("⚠️ No shipping label found in storage when updating refund")
                return shippingLabel.copy(refund: refund)
            }
            let storageShipment = storageShippingLabel.shipment

            let storageRefund = storageShippingLabel.refund ?? storage.insertNewObject(ofType: Storage.ShippingLabelRefund.self)
            storageRefund.update(with: refund)
            storageShippingLabel.refund = storageRefund

            // update stored shipment to trigger onDidChangeContent notification
            storageShipment?.shippingLabel = storageShippingLabel

            return storageShippingLabel.toReadOnly()

        }, completion: { result in
            switch result {
            case .success(let label):
                onCompletion(label)
            case .failure(let error):
                DDLogError("⛔️ Error upserting shipping label refund: \(error)")
                onCompletion(shippingLabel.copy(refund: refund))
            }
        }, on: .main)
    }

    /// Updates order's `dateModified` locally
    /// Used as temp workaround to reflect that the order instance was updated
    func setLastModifiedDateForOrder(siteID: Int64, orderID: Int64) {
        storageManager.performAndSave({ derivedStorage in
            guard let storedOrder = derivedStorage.loadOrder(
                siteID: siteID,
                orderID: orderID
            ) else {
                return
            }

            storedOrder.dateModified = Date()
        }, completion: nil, on: .main)
    }

    /// Inserts the specified readonly shipping label entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func insertPurchasedLabelInBackground(siteID: Int64,
                                          orderID: Int64,
                                          shippingLabel: ShippingLabel,
                                          onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }

            let storageOrder = storage.loadOrder(siteID: siteID, orderID: orderID)
            let storageShipment = storage.loadAllShipments(siteID: siteID, orderID: orderID)
                .first(where: { $0.index == shippingLabel.shipmentID })

            guard let storageOrder, let storageShipment else { return }

            update(storageShipment: storageShipment,
                   storageOrder: storageOrder,
                   shippingLabel: shippingLabel,
                   using: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates/inserts the specified readonly shipments entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertShipmentsInBackground(siteID: Int64,
                                     orderID: Int64,
                                     shipments: [WooShippingShipment],
                                     onCompletion: @escaping () -> Void) {
        storageManager.performAndSave ({ [weak self] storage in
            guard let self else { return }
            guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
                return
            }
            upsertShipments(siteID: siteID,
                            orderID: orderID,
                            shipments: shipments,
                            storageOrder: order,
                            using: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates/inserts the specified readonly WooShippingShipments entities in the current thread.
    func upsertShipments(siteID: Int64,
                         orderID: Int64,
                         shipments: [WooShippingShipment],
                         storageOrder: StorageOrder,
                         using storage: StorageType) {
        let storedShipments = storage.loadAllShipments(siteID: siteID, orderID: orderID)
        for shipment in shipments {
            let storageShipment = storedShipments.first(where: { $0.index == shipment.index }) ??
            storage.insertNewObject(ofType: Storage.WooShippingShipment.self)
            storageShipment.update(with: shipment)
            storageShipment.order = storageOrder

            handleShipmentItems(shipment, storageShipment, storage)
            update(storageShipment: storageShipment,
                   storageOrder: storageOrder,
                   shippingLabel: shipment.shippingLabel,
                   using: storage)
        }

        // Now, remove any objects that exist in storage but not in shipments
        let shipmentIndices = shipments.map(\.index)
        storedShipments.filter {
            !shipmentIndices.contains($0.index)
        }.forEach {
            storage.deleteObject($0)
        }
    }

    func update(storageShipment: StorageWooShippingShipment,
                storageOrder: StorageOrder,
                shippingLabel: ShippingLabel?,
                using storage: StorageType) {
        if let shippingLabel {
            let storageShippingLabel = storageShipment.shippingLabel ?? storage.insertNewObject(ofType: Storage.ShippingLabel.self)
            storageShippingLabel.update(with: shippingLabel)
            storageShippingLabel.order = storageOrder

            update(storageShippingLabel: storageShippingLabel, refund: shippingLabel.refund, using: storage)

            let originAddress = storageShippingLabel.originAddress ?? storage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            originAddress.update(with: shippingLabel.originAddress)
            storageShippingLabel.originAddress = originAddress

            let destinationAddress = storageShippingLabel.destinationAddress ?? storage.insertNewObject(ofType: Storage.ShippingLabelAddress.self)
            destinationAddress.update(with: shippingLabel.destinationAddress)
            storageShippingLabel.destinationAddress = destinationAddress

            /// Set the shipping label to the shipment's relationship
            storageShipment.shippingLabel = storageShippingLabel
        } else {
            storageShipment.shippingLabel = nil
        }
    }

    /// Updates, inserts, or prunes the provided StorageWooShippingShipment's items using the provided read-only WooShippingShipment's items
    ///
    private func handleShipmentItems(_ readOnlyShipment: Networking.WooShippingShipment,
                                     _ storageShipment: Storage.WooShippingShipment,
                                     _ storage: StorageType) {

        let storageItemsArray = Array(storageShipment.items ?? [])

        // Upsert the items from the read-only shipment
        for readOnlyItem in readOnlyShipment.items {
            if let existingStorageItem = storageItemsArray.first(where: { $0.id == readOnlyItem.id }) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.WooShippingShipmentItem.self)
                newStorageItem.update(with: readOnlyItem)
                storageShipment.addToItems(newStorageItem)
            }
        }

        // Now, remove any objects that exist in storageShipment.items but not in readOnlyShipment.items
        storageItemsArray.forEach { storageItem in
            if readOnlyShipment.items!.contains(where: { $0.id == storageItem.id }) {
                storageShipment.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        }
    }

    func update(storageShippingLabel: StorageShippingLabel,
                refund: ShippingLabelRefund?,
                using storage: StorageType) {
        if let refund {
            let storageRefund = storageShippingLabel.refund ?? storage.insertNewObject(ofType: Storage.ShippingLabelRefund.self)
            storageRefund.update(with: refund)
            storageShippingLabel.refund = storageRefund
        } else {
            storageShippingLabel.refund = nil
        }
    }

    /// Updates/inserts the specified readonly shipping label account settings entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertShippingLabelAccountSettingsInBackground(siteID: Int64,
                                                        accountSettings: ShippingLabelAccountSettings,
                                                        onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            let storageAccountSettings = storage.loadShippingLabelAccountSettings(siteID: siteID) ??
                storage.insertNewObject(ofType: Storage.ShippingLabelAccountSettings.self)
            storageAccountSettings.update(with: accountSettings)

            // Remove all previous payment methods
            storageAccountSettings.paymentMethods?.removeAll()

            // Insert the payment methods from the read-only account settings
            for paymentMethod in accountSettings.paymentMethods {
                let newStoragePaymentMethod = storage.insertNewObject(ofType: Storage.ShippingLabelPaymentMethod.self)
                newStoragePaymentMethod.update(with: paymentMethod)
                storageAccountSettings.addToPaymentMethods(newStoragePaymentMethod)
            }
        }, completion: onCompletion, on: .main)
    }
}

/// Represents errors that can be returned when purchasing a shipping label
public enum WooShippingLabelPurchaseError: Error {
    /// API returns a `PURCHASE_ERROR` status for a label
    case purchaseErrorStatus
    /// No labels are returned by initial purchase request
    case purchaseMissingLabels
    case failedToRefreshSelectedPackage
    case failedToRefreshSelectedRate
}

public enum WooShippingLoadLabelRatesError: Error {
    case invalidDestinationName
}

private extension ShippingLabelCarriersAndRates {
    var hasInvalidDestinationNameRateError: Bool {
        defaultErrors.contains { error in
            error.code == "rate_error" &&
            error.message?.localizedCaseInsensitiveContains("shipment.to_address: invalid name") == true
        }
    }
}
