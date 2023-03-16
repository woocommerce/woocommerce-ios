import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// ViewModel for `BundledProductsList`
///
final class BundledProductsListViewModel {

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
    let bundledProducts: [BundledProduct]

    init(bundledProducts: [BundledProduct]) {
        self.bundledProducts = bundledProducts
    }
}

// MARK: Initializers
extension BundledProductsListViewModel {
    convenience init(siteID: Int64, bundledProducts: [Yosemite.ProductBundleItem], storageManager: StorageManagerType = ServiceLocator.storageManager) {
        let products = BundledProductsListViewModel.fetchProducts(for: siteID, including: bundledProducts.map { $0.productID }, storageManager: storageManager)
        let viewModels = bundledProducts.map { bundledProduct in
            BundledProduct(id: bundledProduct.bundledItemID,
                           title: bundledProduct.title,
                           stockStatus: bundledProduct.stockStatus.description,
                           imageURL: products.first(where: { $0.productID == bundledProduct.productID })?.imageURL) // URL for bundled product's first image
        }
        self.init(bundledProducts: viewModels)
    }
}

// MARK: Private helpers
private extension BundledProductsListViewModel {
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
}

// MARK: Constants
extension BundledProductsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Bundled Products", comment: "Title for the bundled products screen")
        static let infoNotice = NSLocalizedString("You can edit bundled products in the web dashboard.",
                                                  comment: "Info notice at the bottom of the bundled products screen")
    }
}
