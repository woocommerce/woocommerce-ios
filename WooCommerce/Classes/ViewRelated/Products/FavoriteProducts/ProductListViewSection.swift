import Foundation
import struct Yosemite.Product
import UIKit

struct ProductListViewSection {

    enum ProductListViewSectionType {
        case favorites

        case allProducts

        var title: String {
            switch self {
            case .favorites:
                return Localization.favoritesSectionTitle
            case .allProducts:
                return Localization.allProductsSectionTitle
            }
        }
    }

    let type: ProductListViewSectionType
    let products: [Product]
}

private extension ProductListViewSection {
    enum Localization {
        static let favoritesSectionTitle = NSLocalizedString(
            "productListViewModel.favoritesSectionTitle",
            value: "Favorites",
            comment: "Section title for Favorites products section on the Product list screen.")
        static let allProductsSectionTitle = NSLocalizedString(
            "productListViewModel.allProductsSectionTitle",
            value: "All",
            comment: "Section title for all products section on the Product list screen.")
    }
}
