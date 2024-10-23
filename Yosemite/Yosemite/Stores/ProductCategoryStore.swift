import Foundation
import Networking
import Storage

// MARK: - ProductCategoryStore
//
public final class ProductCategoryStore: Store {
    private let remote: ProductCategoriesRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ProductCategoriesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: ProductCategoriesRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case let .synchronizeProductCategories(siteID, fromPageNumber, onCompletion):
            synchronizeAllProductCategories(siteID: siteID, fromPageNumber: fromPageNumber, onCompletion: onCompletion)
        case .addProductCategory(siteID: let siteID, name: let name, parentID: let parentID, onCompletion: let onCompletion):
            addProductCategory(siteID: siteID, name: name, parentID: parentID, onCompletion: onCompletion)
        case .addProductCategories(siteID: let siteID, names: let names, parentID: let parentID, onCompletion: let onCompletion):
            addProductCategories(siteID: siteID, names: names, parentID: parentID, onCompletion: onCompletion)
        case .synchronizeProductCategory(siteID: let siteID, categoryID: let CategoryID, onCompletion: let onCompletion):
            synchronizeProductCategory(siteID: siteID, categoryID: CategoryID, onCompletion: onCompletion)
        case let .updateProductCategory(category, onCompletion):
            updateProductCategory(category, onCompletion: onCompletion)
        case let .deleteProductCategory(siteID, categoryID, onCompletion):
            deleteProductCategory(siteID: siteID, categoryID: categoryID, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services
//
private extension ProductCategoryStore {

    /// Synchronizes all product categories associated with a given Site ID, starting at a specific page number.
    ///
    func synchronizeAllProductCategories(siteID: Int64, fromPageNumber: Int, onCompletion: @escaping (ProductCategoryActionError?) -> Void) {
        // Start fetching the provided initial page
        synchronizeProductCategories(siteID: siteID, pageNumber: fromPageNumber, pageSize: Constants.defaultMaxPageSize) { [weak self] categories, error in
            guard let self = self  else {
                return
            }

            // If there is an error, end the recursion and call `onCompletion` with an `error`
            if let error = error {
                let synchronizationError = ProductCategoryActionError.categoriesSynchronization(pageNumber: fromPageNumber, rawError: error)
                onCompletion(synchronizationError)
                return
            }

            // If categories is nil, end the recursion and call `onCompletion`
            if categories == nil {
                onCompletion(nil)
                return
            }

            // If categories is empty, end the recursion and call `onCompletion`
            if let categories = categories, categories.isEmpty {
                onCompletion(nil)
                return
            }

            // Request the next page recursively
            self.synchronizeAllProductCategories(siteID: siteID, fromPageNumber: fromPageNumber + 1, onCompletion: onCompletion)
        }
    }

    /// Synchronizes product categories associated with a given Site ID.
    ///
    func synchronizeProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping ([ProductCategory]?, Error?) -> Void) {
        remote.loadAllProductCategories(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (productCategories, error) in
            guard let productCategories = productCategories else {
                onCompletion(nil, error)
                return
            }

            let deleteUnusedCategories = pageNumber == Default.firstPageNumber
            self?.upsertStoredProductCategoriesInBackground(productCategories,
                                                            siteID: siteID,
                                                            shouldDeleteUnusedCategories: deleteUnusedCategories) {
                onCompletion(productCategories, nil)
            }
        }
    }

    /// Create a new product category associated with a given Site ID.
    ///
    func addProductCategory(siteID: Int64, name: String, parentID: Int64?, onCompletion: @escaping (Result<ProductCategory, Error>) -> Void) {
        remote.createProductCategory(for: siteID, name: name, parentID: parentID) { [weak self] result in
            switch result {
            case .success(let productCategory):
                self?.upsertStoredProductCategoriesInBackground([productCategory], siteID: siteID) {
                    onCompletion(.success(productCategory))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Create new product categories associated with a given Site ID.
    ///
    func addProductCategories(siteID: Int64,
                              names: [String],
                              parentID: Int64?,
                              onCompletion: @escaping (Result<[ProductCategory], Error>) -> Void) {
        remote.createProductCategories(for: siteID, names: names, parentID: parentID) { [weak self] result in
            switch result {
            case .success(let productCategories):
                self?.upsertStoredProductCategoriesInBackground(productCategories, siteID: siteID) {
                    onCompletion(.success(productCategories))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Loads a remote product category associated with the given Category ID and Site ID
    ///
    func synchronizeProductCategory(siteID: Int64, categoryID: Int64, onCompletion: @escaping (Result<ProductCategory, Error>) -> Void) {
        remote.loadProductCategory(with: categoryID, siteID: siteID) { [weak self] result in
            switch result {
            case .success(let productCategory):
                self?.upsertStoredProductCategoriesInBackground([productCategory], siteID: siteID) {
                    onCompletion(.success(productCategory))
                }
            case .failure(let error):
                if let error = error as? DotcomError,
                   case .resourceDoesNotExist = error {
                    onCompletion(.failure(ProductCategoryActionError.categoryDoesNotExistRemotely))
                } else {
                    onCompletion(.failure(error))
                }
            }
        }
    }

    /// Deletes any Storage.ProductCategory  that is not associated to a product on the specified `siteID`
    ///
    func deleteUnusedStoredProductCategories(siteID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteUnusedProductCategories(siteID: siteID)
        }, completion: onCompletion, on: .main)
    }

    /// Updates an existing product category.
    ///
    func updateProductCategory(_ category: ProductCategory, onCompletion: @escaping (Result<ProductCategory, Error>) -> Void) {
        Task { @MainActor in
            do {
                let updatedCategory = try await remote.updateProductCategory(category)
                upsertStoredProductCategoriesInBackground([updatedCategory], siteID: updatedCategory.siteID) {
                    onCompletion(.success(updatedCategory))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Deletes an existing product category.
    ///
    func deleteProductCategory(siteID: Int64, categoryID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                try await remote.deleteProductCategory(for: siteID, categoryID: categoryID)
                deleteUnusedStoredProductCategories(siteID: siteID) {
                    onCompletion(.success(()))
                }
            } catch {
                onCompletion(.failure(error))
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
                                                   shouldDeleteUnusedCategories: Bool = false,
                                                   onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            if shouldDeleteUnusedCategories {
                storage.deleteUnusedProductCategories(siteID: siteID)
            }
            upsertStoredProductCategories(readOnlyProductCategories, in: storage, siteID: siteID)
        }, completion: onCompletion, on: .main)
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

        // Fetch all stored categories
        let storedCategories = storage.loadProductCategories(siteID: siteID)

        // Upserts the ProductCategory models from the read-only version
        for readOnlyProductCategory in readOnlyProductCategories {
            let storageProductCategory: Storage.ProductCategory = {
                if let storedCategory = storedCategories.first(where: { $0.categoryID == readOnlyProductCategory.categoryID }) {
                    return storedCategory
                }
                return storage.insertNewObject(ofType: Storage.ProductCategory.self)
            }()
            storageProductCategory.update(with: readOnlyProductCategory)
        }
    }
}

// MARK: - Constant
//
private extension ProductCategoryStore {
    enum Constants {
        /// Max number allowed by the API to maximize our chances on getting all item in one request.
        ///
        static let defaultMaxPageSize = 100
    }
}
