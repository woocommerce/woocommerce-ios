import Foundation
import protocol Storage.GRDBManagerProtocol
import protocol Networking.ProductVariationsRemoteProtocol

/// Fetch strategy for searching products in the local GRDB catalog using SQL LIKE queries
public struct PointOfSaleLocalSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let searchTerm: String
    private let grdbManager: GRDBManagerProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking
    private let pageSize: Int

    init(siteID: Int64,
         searchTerm: String,
         grdbManager: GRDBManagerProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking,
         pageSize: Int = 25) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.grdbManager = grdbManager
        self.variationsRemote = variationsRemote
        self.analytics = analytics
        self.pageSize = pageSize
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
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

        return PagedItems(items: products,
                         hasMorePages: hasMorePages,
                         totalItems: totalCount)
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
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
