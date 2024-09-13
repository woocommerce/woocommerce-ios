import UIKit
import Yosemite
import protocol Storage.StorageManagerType

final class WooShippingItemsResultsControllers {

    private let siteID: Int64
    private let orderItems: [OrderItem]
    private let storageManager: StorageManagerType
    private var onProductReload: (([Product]) -> Void)?
    private var onProductVariationsReload: (([ProductVariation]) -> Void)?

    /// Stored products that match the items in the order.
    ///
    var products: [Product] {
        try? productResultsController.performFetch()
        return productResultsController.fetchedObjects
    }

    /// Stored product variations that match the items in the order.
    ///
    var productVariations: [ProductVariation] {
        try? productVariationResultsController.performFetch()
        return productVariationResultsController.fetchedObjects
    }

    /// Product ResultsController.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let productIDs = orderItems.map(\.productID)
        let predicate = NSPredicate(format: "siteID == %lld AND productID in %@", siteID, productIDs)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// ProductVariation ResultsController.
    ///
    private lazy var productVariationResultsController: ResultsController<StorageProductVariation> = {
        let variationIDs = orderItems.map(\.variationID).filter { $0 != 0 }
        let predicate = NSPredicate(format: "siteID == %lld AND productVariationID in %@", siteID, variationIDs)

        return ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()


    init(siteID: Int64,
         orderItems: [OrderItem],
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onProductReload: @escaping ([Product]) -> Void,
         onProductVariationsReload: @escaping ([ProductVariation]) -> Void) {
        self.siteID = siteID
        self.orderItems = orderItems
        self.storageManager = storageManager
        configureProductResultsController(onReload: onProductReload)
        configureProductVariationResultsController(onReload: onProductVariationsReload)
    }

    private func configureProductResultsController(onReload: @escaping ([Product]) -> ()) {
        productResultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }
            onReload(self.productResultsController.fetchedObjects)
        }

        productResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            try? self.productResultsController.performFetch()
            onReload(self.productResultsController.fetchedObjects)
        }

        do {
            try productResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for Woo Shipping label creation: \(error)")
        }
    }

    private func configureProductVariationResultsController(onReload: @escaping ([ProductVariation]) -> Void) {
        productVariationResultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }
            onReload(self.productVariationResultsController.fetchedObjects)
        }

        productVariationResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            try? self.productVariationResultsController.performFetch()
            onReload(self.productVariationResultsController.fetchedObjects)
        }

        do {
            try productVariationResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching product variations for Woo Shipping label creation: \(error)")
        }
    }
}
