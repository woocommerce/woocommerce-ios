import Foundation
import Yosemite


/// Results controllers used to render the Refund Details view
///
final class RefundDetailsResultController {
    /// Product ResultsController.
    ///
    private lazy var productResultsController: GenericResultsController<StorageProduct, ProductListItem> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return GenericResultsController<StorageProduct, ProductListItem>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor],
            transformer: { $0.toListItem() }
        )
    }()

    /// Products from an Order
    ///
    var products: [ProductListItem] {
        productResultsController.fetchedObjects
    }

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    /// Configure the result controller(s)
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureProductResultsController(onReload: onReload)
    }
}

// MARK: - Configuring results controllers
//
private extension RefundDetailsResultController {
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
