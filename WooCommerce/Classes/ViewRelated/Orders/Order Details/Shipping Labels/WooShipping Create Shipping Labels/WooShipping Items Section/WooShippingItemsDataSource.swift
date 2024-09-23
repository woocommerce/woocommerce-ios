import UIKit
import Yosemite
import protocol Storage.StorageManagerType

/// Provides data about items to ship for an order with the Woo Shipping extension.
///
protocol WooShippingItemsDataSource {
    var items: [ShippingLabelPackageItem] { get }
    var orderItems: [OrderItem] { get }
    var products: [Product] { get }
    var productVariations: [ProductVariation] { get }
}

final class DefaultWooShippingItemsDataSource: WooShippingItemsDataSource {
    private let order: Order
    private let storageManager: StorageManagerType
    private let stores: StoresManager

    /// Items to ship from an order.
    ///
    var items: [ShippingLabelPackageItem] {
        order.items.compactMap { ShippingLabelPackageItem(orderItem: $0, products: products, productVariations: productVariations) }
    }

    /// Items in the order.
    ///
    var orderItems: [OrderItem] {
        order.items
    }

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
        let productIDs = order.items.map(\.productID)
        let predicate = NSPredicate(format: "siteID == %lld AND productID in %@", order.siteID, productIDs)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// ProductVariation ResultsController.
    ///
    private lazy var productVariationResultsController: ResultsController<StorageProductVariation> = {
        let variationIDs = order.items.map(\.variationID).filter { $0 != 0 }
        let predicate = NSPredicate(format: "siteID == %lld AND productVariationID in %@", order.siteID, variationIDs)

        return ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()


    init(order: Order,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.storageManager = storageManager
        self.stores = stores

        configureProductResultsController()
        configureProductVariationResultsController()
        syncProducts()
        syncProductVariations()
    }

    private func configureProductResultsController() {
        do {
            try productResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching products for Woo Shipping label creation: \(error)")
        }
    }

    private func configureProductVariationResultsController() {
        do {
            try productVariationResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching product variations for Woo Shipping label creation: \(error)")
        }
    }

    private func syncProducts() {
        let action = ProductAction.requestMissingProducts(for: order) { error in
            if let error {
                DDLogError("⛔️ Error synchronizing products for Woo Shipping label creation: \(error)")
                return
            }
        }

        stores.dispatch(action)
    }

    private func syncProductVariations() {
        let action = ProductVariationAction.requestMissingVariations(for: order) { error in
            if let error {
                DDLogError("⛔️ Error synchronizing product variations for Woo Shipping label creation: \(error)")
                return
            }
        }
        stores.dispatch(action)
    }
}
