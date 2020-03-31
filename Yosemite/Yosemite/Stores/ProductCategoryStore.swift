import Foundation
import Networking
import Storage

// MARK: - ProductCategoryStore
//
public final class ProductCategoryStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductCategoryAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductCategoryAction else {
            assertionFailure("ProductCategoryStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductCategories(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductCategories(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services
//
private extension ProductCategoryStore {

    /// Synchronizes product categories associated with a given Site ID.
    ///
    func synchronizeProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductCategoriesRemote(network: network)

        remote.loadAllProductCategories(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (productCategories, error) in
            guard let productCategories = productCategories else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductCategoriesInBackground(productCategories, siteID: siteID) {
                onCompletion(nil)
            }
        }
    }
}

// MARK: - Storage: ProductCategory
//
private extension ProductCategoryStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductCategory Entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertStoredProductCategoriesInBackground(_ readOnlyProductCategories: [Networking.ProductCategory],
                                                   siteID: Int64,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductCategories(readOnlyProductCategories, in: derivedStorage, siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

private extension ProductCategoryStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductCategory entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProducCategories: Remote ProductCategories to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the ProductCategory.
    ///
    func upsertStoredProductCategories(_ readOnlyProductCategories: [Networking.ProductCategory],
                                       in storage: StorageType,
                                       siteID: Int64) {
        // Upserts the ProductCategory models from the read-only version
        for readOnlyProductCategory in readOnlyProductCategories {
            let storageProductCategory: Storage.ProductCategory = {
                if let storedCategory = storage.loadProductCategory(siteID: siteID, categoryID: readOnlyProductCategory.categoryID) {
                    return storedCategory
                }
                return storage.insertNewObject(ofType: Storage.ProductCategory.self)
            }()
            storageProductCategory.update(with: readOnlyProductCategory)
        }
    }
}
