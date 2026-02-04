import Foundation
import protocol Storage.GRDBManagerProtocol
import protocol Networking.ProductVariationsRemoteProtocol

/// Fetch strategy for searching products in the local GRDB catalog using SQL LIKE queries.
/// This is the legacy fallback when FTS search is disabled but local catalog is enabled.
struct PointOfSaleLegacyLocalSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let searchTerm: String
    private let grdbManager: GRDBManagerProtocol
    // periphery:ignore - Reserved for future variation fetching from remote when not in local catalog
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking
    private let pageSize: Int
    private let posProductsOnly: Bool

    init(siteID: Int64,
         searchTerm: String,
         grdbManager: GRDBManagerProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking,
         pageSize: Int = 25,
         posProductsOnly: Bool = false) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.grdbManager = grdbManager
        self.variationsRemote = variationsRemote
        self.analytics = analytics
        self.pageSize = pageSize
        self.posProductsOnly = posProductsOnly
    }

    var debounceStrategy: SearchDebounceStrategy {
        // Use simple debouncing for local search: always debounce to prevent excessive queries
        // even though local searches are fast. 100ms provides responsive feel while preventing
        // queries on every keystroke. Delay loading indicators by 150ms to avoid flicker for fast queries.
        .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)
    }

    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let startTime = Date()

        // Get total count and persisted products in one transaction
        let (persistedProducts, totalCount) = try await grdbManager.databaseConnection.read { db in
            let totalCount = try PersistedProduct
                .posProductSearch(siteID: siteID, searchTerm: searchTerm)
                .fetchCount(db)

            let offset = (pageNumber - 1) * pageSize
            let persistedProducts = try PersistedProduct
                .posProductSearch(siteID: siteID, searchTerm: searchTerm)
                .limit(pageSize, offset: offset)
                .fetchAll(db)

            return (persistedProducts, totalCount)
        }

        // Convert to POSProduct outside the read transaction
        // toPOSProduct(db:) starts its own transaction, so we can't call it inside another transaction
        let products = try persistedProducts.map { persistedProduct in
            try persistedProduct.toPOSProduct(db: grdbManager.databaseConnection)
        }

        let hasMorePages = (pageNumber * pageSize) < totalCount

        if pageNumber == 1 {
            let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
            analytics.trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                           totalItems: totalCount)
        }

        return PagedItems(items: products,
                         hasMorePages: hasMorePages,
                         totalItems: totalCount)
    }

    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        // Get total count and persisted variations in one transaction
        let (persistedVariations, totalCount) = try await grdbManager.databaseConnection.read { db in
            let totalCount = try PersistedProductVariation
                .posVariationsRequest(siteID: siteID, parentProductID: parentProductID)
                .fetchCount(db)

            let offset = (pageNumber - 1) * pageSize
            let persistedVariations = try PersistedProductVariation
                .posVariationsRequest(siteID: siteID, parentProductID: parentProductID)
                .limit(pageSize, offset: offset)
                .fetchAll(db)

            return (persistedVariations, totalCount)
        }

        // Convert to POSProductVariation outside the read transaction
        let variations = try persistedVariations.map { persistedVariation in
            try persistedVariation.toPOSProductVariation(db: grdbManager.databaseConnection)
        }

        let hasMorePages = (pageNumber * pageSize) < totalCount

        return PagedItems(items: variations,
                         hasMorePages: hasMorePages,
                         totalItems: totalCount)
    }
}
