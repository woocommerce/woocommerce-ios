import Foundation
import Yosemite

final class ProductCategoryListViewModel {

    private let product: Product

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

    /// Load existing categories from storage and fire the synchronize product categories action
    ///
    func performInitialFetch() {
        syncronizeCategories()
        try? resultController.performFetch()
    }

    /// Observes and notifies of changes made to product categories
    ///
    func observeCategoryListChanges(onReload: @escaping () -> (Void)) {
        observeResultControllerChanges(onReload: onReload)
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
    func syncronizeCategories() {
        /// TODO-2020: Page Number and PageSized to be updated when `SyncingCoordinator` is implemented.
        let action = ProductCategoryAction.synchronizeProductCategories(siteID: product.siteID, pageNumber: 1, pageSize: 30) { error in
            if let error = error {
                DDLogError("⛔️ Error fetching product categories: \(error.localizedDescription)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    func observeResultControllerChanges(onReload: @escaping () -> (Void)) {
        resultController.onDidChangeContent = {
            onReload()
        }
    }
}
