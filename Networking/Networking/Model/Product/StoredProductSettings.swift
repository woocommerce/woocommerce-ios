#if os(iOS)

import Foundation
import Codegen

/// Models a pair of `siteID` and Product Settings
/// These entities will be serialised to a plist file using `ProductsModuleSettings`
///
public struct StoredProductSettings: Codable, Equatable, GeneratedFakeable {

    public struct Setting: Codable, Equatable {
        public let siteID: Int64
        public let sort: String?
        public let stockStatusFilter: ProductStockStatus?
        public let productStatusFilter: ProductStatus?
        public let productTypeFilter: ProductType?
        public let productCategoryFilter: ProductCategory?

        public init(siteID: Int64,
                    sort: String?,
                    stockStatusFilter: ProductStockStatus?,
                    productStatusFilter: ProductStatus?,
                    productTypeFilter: ProductType?,
                    productCategoryFilter: ProductCategory?) {
            self.siteID = siteID
            self.sort = sort
            self.stockStatusFilter = stockStatusFilter
            self.productStatusFilter = productStatusFilter
            self.productTypeFilter = productTypeFilter
            self.productCategoryFilter = productCategoryFilter
        }

        public func numberOfActiveFilters() -> Int {
            var total = 0
            if stockStatusFilter != nil {
                total += 1
            }
            if productStatusFilter != nil {
                total += 1
            }
            if productTypeFilter != nil {
                total += 1
            }

            if productCategoryFilter != nil {
                total += 1
            }

            return total
        }
    }

    /// SiteID: Setting
    public let settings: [Int64: Setting]

    public init(settings: [Int64: Setting]) {
        self.settings = settings
    }
}

#endif
