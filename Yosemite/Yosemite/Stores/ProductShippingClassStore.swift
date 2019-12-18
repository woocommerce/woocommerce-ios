import Foundation
import Networking
import Storage

// MARK: - ProductShippingClassStore
//
public final class ProductShippingClassStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

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
        case .retrieveProductShippingClass(let product, let onCompletion):
            retrieveProductShippingClass(product: product, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductShippingClassStore {

    /// Synchronizes the `ProductShippingClass`s associated with a given Site ID (if any!).
    ///
    func synchronizeProductShippingClassModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductShippingClassRemote(network: network)

        remote.loadAll(for: siteID) { [weak self] (models, error) in
            guard let models = models else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductShippingClassModelsInBackground(readOnlyProductShippingClassModels: models,
                                                                     siteID: siteID) {
                                                                        onCompletion(nil)
            }
        }
    }

    /// Retrieves the `ProductShippingClass` associated with a given `Product`.
    ///
    func retrieveProductShippingClass(product: Product, onCompletion: @escaping (ProductShippingClass?, Error?) -> Void) {
        let remote = ProductShippingClassRemote(network: network)

        guard product.shippingClassID != 0 else {
            onCompletion(nil, nil)
            return
        }

        remote.loadOne(for: Int64(product.siteID), remoteID: Int64(product.shippingClassID)) { [weak self] (model, error) in
            guard let model = model else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredProductShippingClassModelInBackground(readOnlyProductShippingClassModel: model,
                                                                    for: product) {
                                                                        onCompletion(model, nil)
            }
        }
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

    /// Updates (OR Inserts) the specified ReadOnly ProductShippingClass Entity associated with a Product
    /// *in a background thread*. onCompletion will be called on the main thread!
    ///
    func upsertStoredProductShippingClassModelInBackground(readOnlyProductShippingClassModel: Networking.ProductShippingClass,
                                                           for product: Product,
                                                           onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductShippingClassModel(readOnlyProductShippingClass: readOnlyProductShippingClassModel,
                                                        for: product,
                                                        in: derivedStorage)
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

    /// Updates (OR Inserts) the specified ReadOnly ProductShippingClass associated with a Product into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductShippingClass: Remote ProductShippingClass to be persisted.
    ///     - product: the Product that is set to the ProductShippingClass.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredProductShippingClassModel(readOnlyProductShippingClass: Networking.ProductShippingClass,
                                               for product: Product,
                                               in storage: StorageType) {
        let storageProductShippingClass = storage.loadProductShippingClass(siteID: Int64(product.siteID),
                                                                           remoteID: Int64(product.shippingClassID))
            ?? storage.insertNewObject(ofType: Storage.ProductShippingClass.self)
        storageProductShippingClass.update(with: readOnlyProductShippingClass)
    }
}
