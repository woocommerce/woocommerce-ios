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
        return self?.description ?? NSLocalizedString("Any", comment: "This text appears as a filter option label in the WooCommerce order filtering screens, specifically for date range and order status filters, indicating that no specific filter is applied (showing all items).")
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
        productType.filterListPresentableDescription
    }

    var isActive: Bool {
        productType.isActive
    }
}

private extension ProductType {
    enum Localization {
        static let service = NSLocalizedString(
            "ProductType.service",
            value: "Service",
            comment: "Bookable product type label interpretation as Service. Presented in product type picker in filters."
        )
    }

    /// Override the presentable label of `Booking` product presented in filters
    /// "Booking" should be presented as "Service"
    var filterListPresentableDescription: String {
        switch self {
        case .booking:
            return Localization.service
        default:
            return description
        }
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
