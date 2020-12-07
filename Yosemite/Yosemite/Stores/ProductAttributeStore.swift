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
        case let .synchronizeProductAttributes(siteID, onCompletion):
            synchronizeProductAttributes(siteID: siteID, onCompletion: onCompletion)
        case .addProductAttribute(siteID: let siteID, name: let name, onCompletion: let onCompletion):
            // TODO
            break
        case .updateProductAttribute(siteID: let siteID, productAttributeID: let productAttributeID, name: let name, onCompletion: let onCompletion):
            // TODO
            break
        case .deleteProductAttribute(siteID: let siteID, productAttributeID: let productAttributeID, onCompletion: let onCompletion):
            // TODO
            break
        }
    }
}

// MARK: - Services
//
private extension ProductAttributeStore {

    /// Synchronizes global product attributes associated with a given Site ID.
    ///
    func synchronizeProductAttributes(siteID: Int64, onCompletion: @escaping (Result<[ProductAttribute], Error>) -> Void) {
        remote.loadAllProductAttributes(for: siteID) { (result) in
            switch result {
            case .success(let productAttributes):
                self.upsertStoredProductAttributesInBackground(productAttributes, siteID: siteID) {
                    onCompletion(.success(productAttributes))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
//        remote.loadAllProductCategories(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (productCategories, error) in
//            guard let productCategories = productCategories else {
//                onCompletion(nil, error)
//                return
//            }
//
//            if pageNumber == Default.firstPageNumber {
//                self?.deleteUnusedStoredProductCategories(siteID: siteID)
//            }
//
//            self?.upsertStoredProductCategoriesInBackground(productCategories, siteID: siteID) {
//                onCompletion(productCategories, nil)
//            }
//        }
    }

    /// Create a new product category associated with a given Site ID.
    ///
//    func addProductCategory(siteID: Int64, name: String, parentID: Int64?, onCompletion: @escaping (Result<ProductCategory, Error>) -> Void) {
//        remote.createProductCategory(for: siteID, name: name, parentID: parentID) { [weak self] result in
//            switch result {
//            case .success(let productCategory):
//                self?.upsertStoredProductCategoriesInBackground([productCategory], siteID: siteID) {
//                    onCompletion(.success(productCategory))
//                }
//            case .failure(let error):
//                onCompletion(.failure(error))
//            }
//        }
//    }
//
//    /// Deletes any Storage.ProductCategory  that is not associated to a product on the specified `siteID`
//    ///
//    func deleteUnusedStoredProductCategories(siteID: Int64) {
//        let storage = storageManager.viewStorage
//        storage.deleteUnusedProductCategories(siteID: siteID)
//        storage.saveIfNeeded()
//    }
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
                if let storedAttribute = storage.loadProductAttribute(attributeID: readOnlyProductAttribute.attributeID) {
                    return storedAttribute
                }
                return storage.insertNewObject(ofType: Storage.ProductAttribute.self)
            }()
            storageProductAttribute.update(with: readOnlyProductAttribute)
        }
    }
}
