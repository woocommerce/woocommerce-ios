import Foundation
import Yosemite

/// ProductType promotable on filter lists.
///
struct PromotableProductType: Equatable {
    /// Product Type
    ///
    let productType: ProductType

    /// Wether the product is available in the store
    ///
    let isAvailable: Bool

    /// Associated extension URL to promote.
    ///
    let promoteUrl: URL?
}

extension Optional: FilterType where Wrapped: FilterType {
    var description: String {
        return self?.description ?? NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }

    var isActive: Bool {
        return self != nil
    }
}

extension ProductStockStatus: FilterType {
    var isActive: Bool {
        return true
    }
}

extension ProductStatus: FilterType {
    var isActive: Bool {
        return true
    }
}

extension PromotableProductType: FilterType {

    /// Raw value, used for analytics.
    ///
    var rawValue: String {
        productType.rawValue
    }

    var description: String {
        productType.description
    }

    var isActive: Bool {
        productType.isActive
    }
}

extension ProductType: FilterType {
    var isActive: Bool {
        return true
    }
}

extension ProductCategory: FilterType {
    var description: String {
        return name
    }

    var isActive: Bool {
        return true
    }
}
