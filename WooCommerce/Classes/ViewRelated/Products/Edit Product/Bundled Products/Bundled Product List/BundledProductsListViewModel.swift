import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// ViewModel for `BundledProductsList`
///
final class BundledProductsListViewModel: ObservableObject {

    /// Represents a bundled product
    ///
    struct BundledProduct: Identifiable {
        /// Bundled product ID
        let id: Int64

        /// Title of the bundled product
        let title: String

        /// Stock status of the bundled product
        let stockStatus: String

        /// URL of the bundled product's image, if any
        let imageURL: URL?
    }

    /// View title
    ///
    let title = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice

    /// Bundled products
    ///
    @Published var bundledProducts: [BundledProduct]

    init(bundledProducts: [BundledProduct]) {
        self.bundledProducts = bundledProducts
    }
}

// MARK: Initializers
extension BundledProductsListViewModel {
    convenience init(siteID: Int64,
                     bundleItems: [Yosemite.ProductBundleItem],
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     stores: StoresManager = ServiceLocator.stores) {
        let products = BundledProductsListViewModel.fetchProducts(for: siteID, including: bundleItems.map { $0.productID }, storageManager: storageManager)
        let viewModels = BundledProductsListViewModel.getViewModels(for: bundleItems, with: products, siteID: siteID)
        self.init(bundledProducts: viewModels)

        // Re-sync bundled products to get product images if needed
        synchronizeBundledProductsIfNeeded(for: bundleItems, siteID: siteID, stores: stores)
    }
}

// MARK: Private helpers
private extension BundledProductsListViewModel {
    /// Creates `BundledProduct` view models for the provided Product Bundle Items
    ///
    static func getViewModels(for bundleItems: [ProductBundleItem], with products: [Product], siteID: Int64) -> [BundledProduct] {
        bundleItems.map { bundleItem in
            BundledProduct(id: bundleItem.bundledItemID,
                           title: bundleItem.title,
                           stockStatus: bundleItem.stockStatus.description,
                           imageURL: products.first(where: { $0.productID == bundleItem.productID })?.imageURL) // URL for bundle item's first image
        }
    }

    /// Fetches the provided product IDs from storage
    ///
    static func fetchProducts(for siteID: Int64, including productIDs: [Int64], storageManager: StorageManagerType) -> [Product] {
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", siteID, productIDs)
        let controller = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [])

        do {
            try controller.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch products for Bundled Products list: \(error)")
        }

        return controller.fetchedObjects
    }

    /// Synchronizes the products matching the provided Product Bundle Items, to retrieve their product images
    ///
    func synchronizeBundledProductsIfNeeded(for bundleItems: [ProductBundleItem], siteID: Int64, stores: StoresManager) {
        // We only need to sync if the bundled products are missing images
        guard bundledProducts.filter({ $0.imageURL == nil }).isNotEmpty else { return }

        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: bundleItems.map { $0.productID }) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success((products, _)):
                self.bundledProducts = BundledProductsListViewModel.getViewModels(for: bundleItems, with: products, siteID: siteID)
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products: \(error)")
            }
        }

        stores.dispatch(action)
    }
}

// MARK: Constants
extension BundledProductsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Bundled Products", comment: "Title for the bundled products screen")
        static let infoNotice = NSLocalizedString("You can edit bundled products in the web dashboard.",
                                                  comment: "Info notice at the bottom of the bundled products screen")
    }
}
