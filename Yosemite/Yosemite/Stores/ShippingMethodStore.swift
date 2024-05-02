import Foundation
import Networking
import Storage

/// Handles `ShippingMethodAction` actions
///
public final class ShippingMethodStore: Store {
    private let remote: ShippingMethodsRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public init(remote: ShippingMethodsRemote,
                dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        let remote = ShippingMethodsRemote(network: network)
        self.init(remote: remote,
                  dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network)
    }

    /// Registers to support `ShippingMethodAction`
    ///
    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ShippingMethodAction.self)
    }

    /// Receives and executes actions
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? ShippingMethodAction else {
            assertionFailure("ShippingMethodStore receives an unsupported action!")
            return
        }

        switch action {
        case let .synchronizeShippingMethods(siteID, completion):
            synchronizeShippingMethods(siteID: siteID, completion: completion)
        }
    }
}

// MARK: - Network request
//
private extension ShippingMethodStore {
    /// Fetches all the shipping methods associated with the provided `siteID` and saves them in the Storage layer.
    ///
    func synchronizeShippingMethods(siteID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                let shippingMethods = try await remote.loadShippingMethods(for: siteID)
                upsertShippingMethodsInBackground(siteID: siteID, readOnlyMethods: shippingMethods) {
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Storage
//
private extension ShippingMethodStore {

    /// Updates or inserts Readonly `ShippingMethod` entities in background.
    /// Triggers `completion` on main thread.
    ///
    func upsertShippingMethodsInBackground(siteID: Int64, readOnlyMethods: [ShippingMethod], completion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self else { return }
            self.upsertShippingMethods(siteID: siteID, readOnlyMethods: readOnlyMethods, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: completion)
        }
    }

    /// Updates or inserts Readonly `ShippingMethod` entities in specified storage.
    ///
    func upsertShippingMethods(siteID: Int64, readOnlyMethods: [ShippingMethod], in storage: StorageType) {
        storage.deleteAllObjects(ofType: Storage.ShippingMethod.self)
        readOnlyMethods.forEach { readOnlyMethod in
            let storageShippingMethod = storage.insertNewObject(ofType: Storage.ShippingMethod.self)
            storageShippingMethod.update(with: readOnlyMethod)
        }
    }
}
