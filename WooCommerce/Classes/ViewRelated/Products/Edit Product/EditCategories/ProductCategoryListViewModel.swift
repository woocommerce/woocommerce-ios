import Foundation
import Yosemite

final class ProductCategoryListViewModel {

    /// Obscure token that allows the view model to retry the synchronizeCategories operation
    ///
    struct RetryToken: Equatable {
        fileprivate let fromPageNumber: Int
    }

    /// Represents the current state of `synchronizeCategories` action. Useful for the consumer to update it's UI upon changes
    ///
    enum SyncingState: Equatable {
        case initialized
        case syncing
        case failed(RetryToken)
        case synced
    }

    /// Product the user is editiing
    ///
    private let product: Product

    /// Closure to be invoked when `synchronizeCategories` state  changes
    ///
    private var onSyncStateChange: ((SyncingState) -> Void)?

    /// Current  category synchronization state
    ///
    private var syncCategoriesState: SyncingState = .initialized {
        didSet {
            guard syncCategoriesState != oldValue else {
                return
            }
            onSyncStateChange?(syncCategoriesState)
        }
    }

    private lazy var resultController: ResultsController<StorageProductCategory> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", self.product.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        return ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(product: Product) {
        self.product = product
    }

    /// Returns the number sections.
    ///
    func numberOfSections() -> Int {
        return resultController.sections.count
    }

    /// Returns the number of items for a given `section` that should be displayed
    ///
    func numberOfRowsInSection(section: Int) -> Int {
        return resultController.sections[section].numberOfObjects
    }

    /// Returns a product category for a given `indexPath`
    ///
    func item(at indexPath: IndexPath) -> ProductCategory {
        return resultController.object(at: indexPath)
    }

    /// Load existing categories from storage and fire the synchronize all categories action.
    ///
    func performFetch() {
        synchronizeAllCategories()
        try? resultController.performFetch()
    }

    /// Retry product categories synchronization when `syncCategoriesState` is on a `.failed` state.
    ///
    func retryCategorySynchronization(retryToken: RetryToken) {
        guard syncCategoriesState == .failed(retryToken) else {
            return
        }
        synchronizeAllCategories(fromPageNumber: retryToken.fromPageNumber)
    }

    /// Observes and notifies of changes made to product categories. the current state will be dispatched upon subscription.
    /// Calling this method will remove any other previous observer.
    ///
    func observeCategoryListStateChanges(onStateChanges: @escaping (SyncingState) -> Void) {
        onSyncStateChange = onStateChanges
        onSyncStateChange?(syncCategoriesState)
    }

    /// Returns `true` if the receiver's product contains the given category. Otherwise returns `false`
    ///
    func isCategorySelected(_ category: ProductCategory) -> Bool {
        return product.categories.contains(category)
    }
}

// MARK: - Synchronize Categories
//
private extension ProductCategoryListViewModel {
    /// Synchronizes all product categories starting at a specific page number. Default initial page number is set on `Default.firstPageNumber`
    ///
    func synchronizeAllCategories(fromPageNumber: Int = Default.firstPageNumber) {
        // Start fetching the provided initial page and set the state as syncsynchronizeCategoriesing
        self.syncCategoriesState = .syncing
        synchronizeCategories(pageNumber: fromPageNumber, pageSize: Default.pageSize) { [weak self] categories, error in
            guard let self = self  else {
                return
            }

            // If there is an error, end the recursion and set the sync state as .failed
            if error != nil {
                let retryToken = RetryToken(fromPageNumber: fromPageNumber)
                self.syncCategoriesState = .failed(retryToken)
                return
            }

            // If there isn't new categories, end the recursion and set the sync state as .synced
            if let categories = categories, categories.isEmpty {
                self.syncCategoriesState = .synced
                return
            }

            // Request the next page recursively
            self.synchronizeAllCategories(fromPageNumber: fromPageNumber + 1)
        }
    }

    /// Synchronizes product categories with a given page number and page size.
    ///
    func synchronizeCategories(pageNumber: Int, pageSize: Int, onCompletion: @escaping (([ProductCategory]?, Error?) -> Void)) {
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: product.siteID,
                                                                        pageNumber: pageNumber,
                                                                        pageSize: pageSize) { categories, error in
            if let error = error {
                DDLogError("⛔️ Error fetching product categories: \(error.localizedDescription)")
            }
            onCompletion(categories, error)
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Constants
//
private extension ProductCategoryListViewModel {
    enum Default {
        public static let firstPageNumber = 1
        public static let pageSize = 100 // Max number allwed by the API to maximize our changces on getting all items in one request.
    }
}
