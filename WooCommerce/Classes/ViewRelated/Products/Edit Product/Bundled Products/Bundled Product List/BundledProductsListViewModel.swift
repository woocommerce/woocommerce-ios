import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// ViewModel for `BundledProductsList`
///
final class BundledProductsListViewModel: ObservableObject {

    /// Represents a bundled product
    ///
    struct BundledProduct: Identifiable {
        /// ID of the bundled product (item ID unique to the bundled product list)
        let id: Int64

        /// Product ID of the bundled product
        let productID: Int64

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
    convenience init(siteID: Int64, bundledProducts: [Yosemite.ProductBundleItem], storageManager: StorageManagerType = ServiceLocator.storageManager) {
        let viewModels = BundledProductsListViewModel.getViewModels(for: bundledProducts, siteID: siteID, storageManager: storageManager)
        self.init(bundledProducts: viewModels)

        // Re-sync bundled products to get product images if needed
        synchronizeBundledProductsIfNeeded(for: siteID) { [weak self] in
            self?.bundledProducts = BundledProductsListViewModel.getViewModels(for: bundledProducts, siteID: siteID, storageManager: storageManager)
        }
    }
}

// MARK: Private helpers
private extension BundledProductsListViewModel {
    /// Creates `BundledProduct` view models for the provided Product Bundle Items
    ///
    static func getViewModels(for bundleItems: [ProductBundleItem], siteID: Int64, storageManager: StorageManagerType) -> [BundledProduct] {
        let products = fetchProducts(for: siteID, including: bundleItems.map { $0.productID }, storageManager: storageManager)
        return bundleItems.map { bundleItem in
            BundledProduct(id: bundleItem.bundledItemID,
                           productID: bundleItem.productID,
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

    /// Synchronizes the products matching the provided product IDs, to retrieve their product images
    ///
    func synchronizeBundledProductsIfNeeded(for siteID: Int64, onCompletion: @escaping () -> Void) {
        // We only need to sync if the bundled products are missing images
        guard bundledProducts.filter({ $0.imageURL == nil }).isNotEmpty else { return }

        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: bundledProducts.map { $0.productID }) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products: \(error)")
            }

            onCompletion()
        }

        ServiceLocator.stores.dispatch(action)
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
