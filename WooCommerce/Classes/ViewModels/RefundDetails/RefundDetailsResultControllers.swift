import Foundation
import Yosemite


/// Results controllers used to render the Refund Details view
///
final class RefundDetailsResultControllers {
    /// Product ResultsController.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Products from an Order
    ///
    var products: [Product] {
        return productResultsController.fetchedObjects
    }

    /// Configure the result controller(s)
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureProductResultsController(onReload: onReload)
    }
}

// MARK: - Configuring results controllers
//
private extension RefundDetailsResultControllers {
    /// Handle product event changes
    ///
    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = {
            onReload()
        }

        productResultsController.onDidResetContent = {
            onReload()
        }

        try? productResultsController.performFetch()
    }
}
