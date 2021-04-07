import Foundation
import Networking
import Storage

// MARK: - ProductShippingClassStore
//
public final class ProductShippingClassStore: Store {
    private let remote: ProductShippingClassRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ProductShippingClassRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductShippingClassAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductShippingClassAction else {
            assertionFailure("ProductShippingClassStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductShippingClassModels(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductShippingClassModels(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .retrieveProductShippingClass(let siteID, let remoteID, let onCompletion):
            retrieveProductShippingClass(siteID: siteID, remoteID: remoteID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductShippingClassStore {

    /// Synchronizes the `ProductShippingClass`s associated with a given Site ID (if any!).
    ///
    func synchronizeProductShippingClassModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        remote.loadAll(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let models):
                guard let self = self else {
                    return
                }

                if pageNumber == Default.firstPageNumber {
                    self.deleteStoredProductShippingClassModels(siteID: siteID)
                }

                self.upsertStoredProductShippingClassModelsInBackground(readOnlyProductShippingClassModels: models,
                                                                        siteID: siteID) {
                                                                            let hasNextPage = models.count == pageSize
                                                                            onCompletion(.success(hasNextPage))
                }
            }
        }
    }

    /// Retrieves the `ProductShippingClass` associated with a given `Product`.
    ///
    func retrieveProductShippingClass(siteID: Int64, remoteID: Int64, onCompletion: @escaping (ProductShippingClass?, Error?) -> Void) {
        remote.loadOne(for: siteID, remoteID: remoteID) { [weak self] (model, error) in
            guard let model = model else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredProductShippingClassModelsInBackground(readOnlyProductShippingClassModels: [model],
                                                                     siteID: siteID) {
                                                        onCompletion(model, nil)
            }
        }
    }

    /// Deletes any Storage.ProductShippingClass with the specified `siteID` and `productID`
    ///
    func deleteStoredProductShippingClassModels(siteID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteProductShippingClasses(siteID: siteID)
        storage.saveIfNeeded()
    }
}


// MARK: - Storage: ProductShippingClass
//
private extension ProductShippingClassStore {

    /// Updates (OR Inserts) the specified ReadOnly ProductShippingClass Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductShippingClassModelsInBackground(readOnlyProductShippingClassModels: [Networking.ProductShippingClass],
                                                            siteID: Int64,
                                                            onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductShippingClassModels(readOnlyProductShippingClassModels: readOnlyProductShippingClassModels,
                                                         in: derivedStorage, siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}


private extension ProductShippingClassStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductShippingClass Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductShippingClassModels: Remote ProductShippingClass's to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the ProductShippingClass.
    ///
    func upsertStoredProductShippingClassModels(readOnlyProductShippingClassModels: [Networking.ProductShippingClass],
                                                in storage: StorageType,
                                                siteID: Int64) {
        // Upserts the ProductShippingClass models from the read-only version
        for readOnlyProductShippingClass in readOnlyProductShippingClassModels {
            let storageProductShippingClass = storage.loadProductShippingClass(siteID: siteID,
                                                                               remoteID: readOnlyProductShippingClass.shippingClassID)
                ?? storage.insertNewObject(ofType: Storage.ProductShippingClass.self)
            storageProductShippingClass.update(with: readOnlyProductShippingClass)
        }
    }
}
