import Foundation
import Networking
import Storage

/// Handles `ShippingMethodAction` actions
///
public final class ShippingMethodStore: Store {
    private let requestHandler: ShippingMethodStoreRequestHandler

    public init(remote: ShippingMethodsRemote,
                dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network) {
        self.requestHandler = ShippingMethodStoreRequestHandler(remote: remote, storageManager: storageManager)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public convenience init(dispatcher: Dispatcher,
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
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ShippingMethodAction.self)
    }

    /// Receives and executes actions
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ShippingMethodAction else {
            assertionFailure("ShippingMethodStore receives an unsupported action!")
            return
        }

        switch action {
        case let .synchronizeShippingMethods(siteID, completion):
            requestHandler.synchronizeShippingMethods(siteID: siteID, completion: completion)
        }
    }
}

private final class ShippingMethodStoreRequestHandler: Sendable {
    let remote: ShippingMethodsRemote
    let storageManager: StorageManagerType

    init(remote: ShippingMethodsRemote, storageManager: StorageManagerType) {
        self.remote = remote
        self.storageManager = storageManager
    }
}

// MARK: - Network request
//
private extension ShippingMethodStoreRequestHandler {
    /// Fetches all the shipping methods associated with the provided `siteID` and saves them in the Storage layer.
    ///
    func synchronizeShippingMethods(siteID: Int64, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
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
private extension ShippingMethodStoreRequestHandler {

    /// Updates or inserts Readonly `ShippingMethod` entities in background.
    /// Triggers `completion` on main thread.
    ///
    func upsertShippingMethodsInBackground(siteID: Int64, readOnlyMethods: [ShippingMethod], completion: @escaping @Sendable () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            self.upsertShippingMethods(siteID: siteID, readOnlyMethods: readOnlyMethods, in: storage)
        }, completion: completion, on: .main)
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
