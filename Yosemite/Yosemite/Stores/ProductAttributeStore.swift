import Foundation
import Networking
import Storage

// MARK: - ProductAttributeStore
//
public final class ProductAttributeStore: Store {
    private let remote: ProductAttributesRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ProductAttributesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductAttributeAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductAttributeAction else {
            assertionFailure("ProductAttributeAction received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductAttributes(let siteID, let onCompletion):
            synchronizeProductAttributes(siteID: siteID, onCompletion: onCompletion)
        case .addProductAttribute(let siteID, let name, let onCompletion):
            addProductAttribute(siteID: siteID, name: name, onCompletion: onCompletion)
        case .updateProductAttribute(siteID: let siteID, productAttributeID: let productAttributeID, name: let name, onCompletion: let onCompletion):
            updateProductAttribute(siteID: siteID, attributeID: productAttributeID, name: name, onCompletion: onCompletion)
        case .deleteProductAttribute(siteID: let siteID, productAttributeID: let productAttributeID, onCompletion: let onCompletion):
            deleteProductAttribute(siteID: siteID, attributeID: productAttributeID, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services
//
private extension ProductAttributeStore {

    /// Synchronizes global product attributes associated with a given Site ID.
    ///
    func synchronizeProductAttributes(siteID: Int64, onCompletion: @escaping (Result<[ProductAttribute], Error>) -> Void) {
        remote.loadAllProductAttributes(for: siteID) { [weak self] (result) in
            switch result {
            case .success(let productAttributes):
                self?.deleteUnusedStoredProductAttributes(siteID: siteID)
                self?.upsertStoredProductAttributesInBackground(productAttributes, siteID: siteID) {
                    onCompletion(.success(productAttributes))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Create a new global product attribute associated with a given Site ID.
    ///
    func addProductAttribute(siteID: Int64, name: String, onCompletion: @escaping (Result<ProductAttribute, Error>) -> Void) {
        remote.createProductAttribute(for: siteID, name: name) { [weak self] (result) in
            switch result {
            case .success(let productAttribute):
                self?.upsertStoredProductAttributesInBackground([productAttribute], siteID: siteID, onCompletion: {
                    onCompletion(.success(productAttribute))
                })
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Update a global product attribute associated with a given Site ID.
    ///
    func updateProductAttribute(siteID: Int64, attributeID: Int64, name: String, onCompletion: @escaping (Result<ProductAttribute, Error>) -> Void) {
        remote.updateProductAttribute(for: siteID, productAttributeID: attributeID, name: name) { [weak self] (result) in
            switch result {
            case .success(let productAttribute):
                self?.upsertStoredProductAttributesInBackground([productAttribute], siteID: siteID, onCompletion: {
                    onCompletion(.success(productAttribute))
                })
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Delete a global product attribute associated with a given Site ID.
    ///
    func deleteProductAttribute(siteID: Int64, attributeID: Int64, onCompletion: @escaping (Result<ProductAttribute, Error>) -> Void) {
        remote.deleteProductAttribute(for: siteID, productAttributeID: attributeID) { [weak self] (result) in
            switch result {
            case .success(let productAttribute):
                self?.deleteStoredProductAttribute(siteID: siteID, attributeID: attributeID)
                onCompletion(.success(productAttribute))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: - Storage: ProductAttribute
//
private extension ProductAttributeStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductAttribute Entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertStoredProductAttributesInBackground(_ readOnlyProductAttributes: [Networking.ProductAttribute],
                                                   siteID: Int64,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductAttributes(readOnlyProductAttributes, in: derivedStorage, siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

private extension ProductAttributeStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductAttribute entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductAttributes: Remote ProductAttributes to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the ProductAttribute.
    ///
    func upsertStoredProductAttributes(_ readOnlyProductAttributes: [Networking.ProductAttribute],
                                       in storage: StorageType,
                                       siteID: Int64) {
        // Upserts the ProductAttribute models from the read-only version
        for readOnlyProductAttribute in readOnlyProductAttributes {
            let storageProductAttribute: Storage.ProductAttribute = {
                if let storedAttribute = storage.loadProductAttribute(siteID: siteID, attributeID: readOnlyProductAttribute.attributeID) {
                    return storedAttribute
                }
                return storage.insertNewObject(ofType: Storage.ProductAttribute.self)
            }()
            storageProductAttribute.update(with: readOnlyProductAttribute)
        }
    }

    /// Deletes any Storage.ProductAttribute with the specified `siteID` and `attributeID`
    ///
    func deleteStoredProductAttribute(siteID: Int64, attributeID: Int64) {
        let storage = storageManager.viewStorage
        guard let productAttribute = storage.loadProductAttribute(siteID: siteID, attributeID: attributeID) else {
            return
        }

        storage.deleteObject(productAttribute)
        storage.saveIfNeeded()
    }

    /// Deletes any Storage.ProductAttribute that is not associated to a product on the specified `siteID`
    ///
    func deleteUnusedStoredProductAttributes(siteID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteUnusedProductAttributes(siteID: siteID)
        storage.saveIfNeeded()
    }
}
