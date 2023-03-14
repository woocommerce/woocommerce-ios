import Foundation
import Yosemite

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
    convenience init(bundledProducts: [Yosemite.ProductBundleItem]) {
        let viewModels = bundledProducts.map {
            BundledProduct(id: $0.bundledItemID, title: $0.title, stockStatus: $0.stockStatus.description)
        }
        self.init(bundledProducts: viewModels)
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
