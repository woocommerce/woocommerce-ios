import Foundation
import protocol Storage.GRDBManagerProtocol
import struct Storage.POSSearchIndex
import struct Storage.POSSearchIndexBuilder
import struct Storage.PersistedProduct
import struct Storage.PersistedProductVariation
import protocol Networking.ProductVariationsRemoteProtocol

/// Fetch strategy for searching products in the local GRDB catalog.
/// Uses FTS5 full-text search when enabled, otherwise falls back to LIKE-based queries.
struct PointOfSaleLocalSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let searchTerm: String
    private let grdbManager: GRDBManagerProtocol
    // periphery:ignore - Reserved for future variation fetching from remote when not in local catalog
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let itemMapper: PointOfSaleItemMapperProtocol
    private let analytics: POSItemFetchAnalyticsTracking
    private let pageSize: Int
    private let posProductsOnly: Bool
    private let isFTSSearchEnabled: Bool

    init(siteID: Int64,
         searchTerm: String,
         grdbManager: GRDBManagerProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         itemMapper: PointOfSaleItemMapperProtocol,
         analytics: POSItemFetchAnalyticsTracking,
         pageSize: Int = 25,
         posProductsOnly: Bool = false,
         isFTSSearchEnabled: Bool = true) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.grdbManager = grdbManager
        self.variationsRemote = variationsRemote
        self.itemMapper = itemMapper
        self.analytics = analytics
        self.pageSize = pageSize
        self.posProductsOnly = posProductsOnly
        self.isFTSSearchEnabled = isFTSSearchEnabled
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

    func fetchMixedItems(pageNumber: Int) async throws -> PagedItems<POSItem>? {
        // When FTS is disabled, return nil to fall back to LIKE-based fetchProducts()
        guard isFTSSearchEnabled else { return nil }

        let startTime = Date()
        let offset = (pageNumber - 1) * pageSize

        let (searchResults, totalCount) = try await grdbManager.databaseConnection.read { db in
            let results = try POSSearchIndexBuilder.search(
                siteID: siteID,
                term: searchTerm,
                limit: pageSize,
                offset: offset,
                in: db
            )
            let count = try POSSearchIndexBuilder.searchCount(siteID: siteID, term: searchTerm, in: db)
            return (results, count)
        }

        let items = try await hydrateSearchResults(searchResults)
        let hasMorePages = (pageNumber * pageSize) < totalCount

        if pageNumber == 1 {
            let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
            analytics.trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                           totalItems: totalCount)
        }

        return PagedItems(items: items, hasMorePages: hasMorePages, totalItems: totalCount)
    }

    private func hydrateSearchResults(_ searchResults: [POSSearchIndex]) async throws -> [POSItem] {
        try await withThrowingTaskGroup(of: POSItem?.self) { group in
            for index in searchResults {
                group.addTask {
                    try await self.hydrateSearchResult(index)
                }
            }

            var items: [POSItem?] = Array(repeating: nil, count: searchResults.count)
            var resultIndex = 0
            for try await item in group {
                items[resultIndex] = item
                resultIndex += 1
            }

            // Filter out nils and maintain order based on search results
            return searchResults.compactMap { index in
                items.first { item in
                    guard let item else { return false }
                    return item.id == POSItemIdentifier(
                        underlyingType: index.itemType == .variation ? .variation : .product,
                        itemID: index.itemID
                    )
                } ?? nil
            }
        }
    }

    private func hydrateSearchResult(_ index: POSSearchIndex) async throws -> POSItem? {
        switch index.itemType {
        case .product:
            guard let product = try await grdbManager.databaseConnection.read({ db in
                try PersistedProduct.fetchOne(db, key: ["siteID": index.siteID, "id": index.itemID])
            }) else {
                return nil
            }
            let posProduct = try product.toPOSProduct(db: grdbManager.databaseConnection)
            return itemMapper.mapProductToPOSItem(product: posProduct)

        case .variation:
            guard let parentProductID = index.parentProductID else { return nil }

            guard let variation = try await grdbManager.databaseConnection.read({ db in
                try PersistedProductVariation.fetchOne(db, key: ["siteID": index.siteID, "id": index.itemID])
            }) else {
                return nil
            }

            guard let parentProduct = try await grdbManager.databaseConnection.read({ db in
                try PersistedProduct.fetchOne(db, key: ["siteID": index.siteID, "id": parentProductID])
            }) else {
                return nil
            }

            let posVariation = try variation.toPOSProductVariation(db: grdbManager.databaseConnection)
            let posParentProduct = try parentProduct.toPOSProduct(db: grdbManager.databaseConnection)

            return itemMapper.mapVariationToSearchResultPOSItem(variation: posVariation, parentProduct: posParentProduct)
        }
    }
}
