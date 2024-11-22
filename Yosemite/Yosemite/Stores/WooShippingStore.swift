import Foundation
import Networking
import Storage

/// Implements `WooShippingAction` actions
///
public final class WooShippingStore: Store {
    private let remote: WooShippingRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.writerDerivedStorage
    }()

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
        }
    }
}

private extension WooShippingStore {
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void) {
        remote.createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption) { result in
            switch result {
            case .success(let packages):
                completion(.success(packages))
            case .failure(let error):
                completion(.failure(PackageCreationError(error: error)))
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
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void) {
        remote.loadPackages(siteID: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let packagesResponse):
                self.upsertShippingStoreOptionsInBackground(siteID: siteID, storeOptions: packagesResponse.storeOptions) {
                    completion(.success(packagesResponse))
                }
            }
        }
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(siteID: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let settings):
                self.upsertShippingAccountSettingsInBackground(siteID: siteID, settings: settings) {
                    completion(.success(settings))
                }
            }
        }
    }

    /// Updates/inserts the specified readonly shipping account settings entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertShippingAccountSettingsInBackground(siteID: Int64,
                                                   settings: WooShippingAccountSettings,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            ShippingLabelStore.upsertShippingLabelAccountSettings(derivedStorage: derivedStorage, siteID: siteID, accountSettings: settings.accountSettings)
            self.upsertShippingStoreOptions(siteID: siteID, storeOptions: settings.storeOptions)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabelStoreOptions entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertShippingStoreOptionsInBackground(siteID: Int64,
                                                storeOptions: ShippingLabelStoreOptions,
                                                onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertShippingStoreOptions(siteID: siteID, storeOptions: storeOptions)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly ShippingLabelStoreOptions entity in the current thread.
    ///
    func upsertShippingStoreOptions(siteID: Int64, storeOptions: ShippingLabelStoreOptions) {
        let derivedStorage = sharedDerivedStorage
        // load store options and account setting separately
        let storageAccountSettings = derivedStorage.loadShippingLabelStoreOptions(siteID: siteID) ??
            derivedStorage.insertNewObject(ofType: Storage.ShippingLabelStoreOptions.self)
        storageAccountSettings.update(with: storeOptions, siteID: siteID)
    }
}
