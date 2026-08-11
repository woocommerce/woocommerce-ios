import Foundation
import Yosemite
import protocol Storage.StorageManagerType


/// Results controllers used to render the Refund Details view
///
final class RefundDetailsResultController {
    /// Product ResultsController.
    ///
    private lazy var productResultsController: GenericResultsController<StorageProduct, OrderDetailsProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return GenericResultsController<StorageProduct, OrderDetailsProduct>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor],
            transformer: { OrderDetailsProduct(storageProduct: $0) }
        )
    }()

    /// ProductVariation ResultsController.
    ///
    private lazy var productVariationResultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld AND productVariationID in %@", siteID, variationIDs)

        return ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Products from an Order
    ///
    var products: [OrderDetailsProduct] {
        productResultsController.fetchedObjects
    }

    /// ProductVariations from an Order
    ///
    var productVariations: [ProductVariation] {
        productVariationResultsController.fetchedObjects
    }

    private let siteID: Int64
    private let variationIDs: [Int64]
    private let storageManager: StorageManagerType

    init(siteID: Int64,
         variationIDs: [Int64],
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.variationIDs = variationIDs
        self.storageManager = storageManager
    }

    /// Configure the result controller(s)
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureProductResultsController(onReload: onReload)
        configureProductVariationResultsController(onReload: onReload)
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

    /// Handle product variation event changes
    ///
    private func configureProductVariationResultsController(onReload: @escaping () -> Void) {
        productVariationResultsController.onDidChangeContent = {
            onReload()
        }

        productVariationResultsController.onDidResetContent = {
            onReload()
        }

        try? productVariationResultsController.performFetch()
    }
}
