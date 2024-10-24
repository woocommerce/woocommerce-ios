import Foundation
import Networking
import Storage


// MARK: - MetaDataStore
//
public final class MetaDataStore: Store {
    private let remote: MetaDataRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: MetaDataRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initializes a new MetaDataStore.
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `MetaDataAction`.
    ///   - storageManager: The storage layer used to store and retrieve persisted MetaData for Orders and Products.
    ///   - network: The network layer used to update MetaData.
    ///
    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: MetaDataRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: MetaDataAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `MetaDataAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? MetaDataAction else {
            assertionFailure("MetaDataStore received an unsupported action")
            return
        }

        switch action {
        case let .updateMetaData(siteID, parentItemId, metaDataType, metadata, onCompletion):
            updateMetaData(siteID: siteID, parentItemID: parentItemId, metaDataType: metaDataType, metadata: metadata, onCompletion: onCompletion)
        }
    }
}

// MARK: - Upsert MetaData for Orders and Products
//
private extension MetaDataStore {
    /// Updates metadata both remotely and in the local database.
    /// - Parameters:
    /// - siteID: Site id of the order.
    /// - parentItemID: ID of the parent item.
    /// - metaDataType: Type of metadata.
    /// - metadata: Metadata to be updated.
    func updateMetaData(siteID: Int64,
                        parentItemID: Int64,
                        metaDataType: MetaDataType,
                        metadata: [[String: Any?]],
                        onCompletion: @escaping (Result<[MetaData], Error>) -> Void) {
        switch metaDataType {
        case .order:
            updateOrderMetaData(siteID: siteID, orderID: parentItemID, metadata: metadata, onCompletion: onCompletion)
        case .product:
            updateProductMetaData(siteID: siteID, productID: parentItemID, metadata: metadata, onCompletion: onCompletion)
        }
    }

    /// Updates order metadata both remotely and in the local database..
    /// - Parameters:
    ///   - siteID: Site id of the order.
    ///   - orderID: ID of the order.
    ///   - metadata: Metadata to be updated.
    ///   - onCompletion: Callback called when the action is finished, including the result of the update operation.
    ///
    func updateOrderMetaData(siteID: Int64,
                             orderID: Int64,
                             metadata: [[String: Any?]],
                             onCompletion: @escaping (Result<[MetaData], Error>) -> Void) {
        Task { @MainActor in
            do {
                let results = try await self.remote.updateMetaData(for: siteID, for: orderID, type: .order, metadata: metadata)
                upsertStoredOrderMetaDataInBackground(readOnlyOrderMetaDatas: results, orderID: orderID, siteID: siteID) {
                    onCompletion(.success(results))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly `MetaData` Entities into the Storage Layer.
    /// - Parameters:
    ///   - readOnlyOrderMetaDatas: Array of read-only order metadata.
    ///   - orderID: ID of the order.
    ///   - siteID: Site id of the order.
    ///   - onCompletion: Callback called when the action is finished.
    ///
    func upsertStoredOrderMetaDataInBackground(readOnlyOrderMetaDatas: [Networking.MetaData],
                                               orderID: Int64,
                                               siteID: Int64,
                                               onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage

        derivedStorage.perform {
            let storedMetaData = derivedStorage.loadOrderMetaData(siteID: siteID, orderID: orderID)

            for readOnlyOrderMetaData in readOnlyOrderMetaDatas {
                self.saveMetaData(derivedStorage, readOnlyOrderMetaData, storedMetaData, orderID: orderID, siteID: siteID)
            }

            storedMetaData.forEach { storedMetaData in
                if !readOnlyOrderMetaDatas.contains(where: { $0.metadataID == storedMetaData.metadataID }) {
                    derivedStorage.deleteObject(storedMetaData)
                }
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Using the provided StorageType, update or insert a Storage.MetaData using the provided ReadOnly
    /// MetaData. This func does *not* persist any unsaved changes to storage.
    /// - Parameters:
    ///   - storage: The storage type to use.
    ///   - readOnlyMetaData: The read-only metadata to save.
    ///   - orderID: ID of the order.
    ///   - siteID: Site id of the order.
    ///
    func saveMetaData(_ storage: StorageType, _ readOnlyMetaData: MetaData, _ storedMetaData: [Storage.MetaData], orderID: Int64, siteID: Int64) {
        if let existingStorageMetaData = storedMetaData.first(where: { $0.metadataID == readOnlyMetaData.metadataID }) {
            existingStorageMetaData.update(with: readOnlyMetaData)
            return
        }

        guard let storageOrder = storage.loadOrder(siteID: siteID, orderID: orderID) else {
            DDLogWarn("⚠️ Could not persist the Order MetaData with ID \(readOnlyMetaData.metadataID) — unable to retrieve stored order with ID \(orderID).")
            return
        }

        let newStorageMetaData = storage.insertNewObject(ofType: Storage.MetaData.self)
        newStorageMetaData.update(with: readOnlyMetaData)
        newStorageMetaData.order = storageOrder
        storageOrder.addToCustomFields(newStorageMetaData)
    }

    /// Updates product metadata both remotely and in the local database.
    /// - Parameters:
    ///   - siteID: Site id of the product.
    ///   - productID: ID of the product.
    ///   - metadata: Metadata to be updated.
    ///   - onCompletion: Callback called when the action is finished, including the result of the update operation.
    ///
    func updateProductMetaData(siteID: Int64,
                               productID: Int64,
                               metadata: [[String: Any?]],
                               onCompletion: @escaping (Result<[MetaData], Error>) -> Void) {
        Task { @MainActor in
            do {
                let results = try await self.remote.updateMetaData(for: siteID, for: productID, type: .product, metadata: metadata)
                upsertStoredProductMetaDataInBackground(readOnlyProductMetaDatas: results, productID: productID, siteID: siteID) {
                    onCompletion(.success(results))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly `MetaData` Entities for given product ID into the Storage Layer.
    /// - Parameters:
    ///   - readOnlyProductMetaDatas: Array of read-only product metadata.
    ///   - productID: ID of the product.
    ///   - siteID: Site id of the product.
    ///   - onCompletion: Callback called when the action is finished.
    ///
    func upsertStoredProductMetaDataInBackground(readOnlyProductMetaDatas: [Networking.MetaData],
                                                 productID: Int64,
                                                 siteID: Int64,
                                                 onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            let storedMetaData = derivedStorage.loadProductMetaData(siteID: siteID, productID: productID)

            for readOnlyProductMetaData in readOnlyProductMetaDatas {
                self.saveMetaData(derivedStorage, readOnlyProductMetaData, storedMetaData, productID: productID, siteID: siteID)
            }

            storedMetaData.forEach { storedMetaData in
                if !readOnlyProductMetaDatas.contains(where: { $0.metadataID == storedMetaData.metadataID }) {
                    derivedStorage.deleteObject(storedMetaData)
                }
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Using the provided StorageType, update or insert a Storage.MetaData using the provided ReadOnly
    /// MetaData. This func does *not* persist any unsaved changes to storage.
    /// - Parameters:
    ///   - storage: The storage type to use.
    ///   - readOnlyMetaData: The read-only metadata to save.
    ///   - productID: ID of the product.
    ///   - siteID: Site id of the product.
    ///
    func saveMetaData(_ storage: StorageType, _ readOnlyMetaData: MetaData, _ storedMetaData: [Storage.MetaData], productID: Int64, siteID: Int64) {
        if let existingStorageMetaData = storedMetaData.first(where: { $0.metadataID == readOnlyMetaData.metadataID }) {
            existingStorageMetaData.update(with: readOnlyMetaData)
            return
        }

        guard let storageOrder = storage.loadProduct(siteID: siteID, productID: productID) else {
            DDLogWarn("⚠️ Could not persist the Product MetaData with ID \(readOnlyMetaData.metadataID) — unable to retrieve stored product with ID \(productID).")
            return
        }

        let newStorageMetaData = storage.insertNewObject(ofType: Storage.MetaData.self)
        newStorageMetaData.update(with: readOnlyMetaData)
        newStorageMetaData.product = storageOrder
        storageOrder.addToCustomFields(newStorageMetaData)
    }
}
