import Foundation
import Testing
import Networking
import class WooFoundation.CurrencySettings
@testable import Storage
@testable import Yosemite

@Suite("PointOfSaleLocalSearchPurchasableItemFetchStrategy Tests")
struct PointOfSaleLocalSearchPurchasableItemFetchStrategyTests {
    private let siteID: Int64 = 123
    private let searchTerm = "test"
    private var grdbManager: GRDBManager!
    private let variationsRemote = MockProductVariationsRemote()
    private let mockAnalytics = MockPOSItemFetchAnalyticsTracking()
    private let mockItemMapper = MockPointOfSaleItemMapper()
    private let itemMapper = PointOfSaleItemMapper(currencySettings: CurrencySettings())

    init() async throws {
        grdbManager = try GRDBManager()

        // Initialize site
        let siteIDLocalCopy = self.siteID
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteIDLocalCopy).insert(db)
        }
    }

    // MARK: - Search Functionality Tests

    @Test("fetchMixedItems returns matching products")
    func test_fetchMixedItems_returns_matching_products() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Test Product"))
        try await insertProduct(makeProduct(id: 2, name: "Another Product"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy()

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.totalItems == 1)
        let item = try #require(result.items.first)
        #expect(item.id == POSItemIdentifier(underlyingType: .product, itemID: 1))
        guard case let .simpleProduct(product) = item else {
            Issue.record("Expected a simple product, got \(item)")
            return
        }
        #expect(product.name == "Test Product")
    }

    @Test("fetchMixedItems searches by SKU")
    func test_fetchMixedItems_searches_by_sku() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Product A", sku: "TEST-SKU-123"))
        try await insertProduct(makeProduct(id: 2, name: "Product B", sku: "OTHER-SKU-456"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy(searchTerm: "TEST-SKU")

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.items.map(\.id) == [POSItemIdentifier(underlyingType: .product, itemID: 1)])
        #expect(result.totalItems == 1)
    }

    @Test("fetchMixedItems searches by global unique ID")
    func test_fetchMixedItems_searches_by_global_unique_id() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Product A", globalUniqueID: "12345678"))
        try await insertProduct(makeProduct(id: 2, name: "Product B", globalUniqueID: "87654321"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy(searchTerm: "12345678")

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.items.map(\.id) == [POSItemIdentifier(underlyingType: .product, itemID: 1)])
        #expect(result.totalItems == 1)
    }

    @Test("fetchMixedItems returns variations with their parent product")
    func test_fetchMixedItems_returns_variations_with_parent_product() async throws {
        // Given
        let parentProductID: Int64 = 100
        try await insertProduct(makeProduct(id: parentProductID, name: "Test Shirt", productTypeKey: "variable"))
        try await insertVariation(makeVariation(id: 1, productID: parentProductID, sku: "TEST-RED"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy(searchTerm: "TEST-RED")

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.totalItems == 1)
        let item = try #require(result.items.first)
        guard case let .searchResultVariation(variation, parentProduct) = item else {
            Issue.record("Expected a search result variation, got \(item)")
            return
        }
        #expect(variation.productVariationID == 1)
        #expect(parentProduct.productID == parentProductID)
        #expect(parentProduct.name == "Test Shirt")
    }

    @Test("fetchMixedItems returns empty result when no matches")
    func test_fetchMixedItems_returns_empty_when_no_matches() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Another Product"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy()

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.items.isEmpty)
        #expect(result.totalItems == 0)
        #expect(result.hasMorePages == false)
    }

    @Test("fetchMixedItems handles pagination correctly")
    func test_fetchMixedItems_handles_pagination_correctly() async throws {
        // Given - insert 30 products
        for index in 1...30 {
            try await insertProduct(makeProduct(id: Int64(index), name: "Test Product \(index)"))
        }
        try await rebuildSearchIndex()
        let strategy = makeStrategy(pageSize: 10)

        // When
        let page1 = try #require(await strategy.fetchMixedItems(pageNumber: 1))
        let page2 = try #require(await strategy.fetchMixedItems(pageNumber: 2))
        let page3 = try #require(await strategy.fetchMixedItems(pageNumber: 3))
        let page4 = try #require(await strategy.fetchMixedItems(pageNumber: 4))

        // Then
        #expect(page1.items.count == 10)
        #expect(page1.hasMorePages == true)
        #expect(page1.totalItems == 30)

        #expect(page2.items.count == 10)
        #expect(page2.hasMorePages == true)
        #expect(page2.totalItems == 30)

        #expect(page3.items.count == 10)
        #expect(page3.hasMorePages == false)
        #expect(page3.totalItems == 30)

        #expect(page4.items.isEmpty)
        #expect(page4.hasMorePages == false)
        #expect(page4.totalItems == 30)
    }

    @Test("fetchMixedItems only returns items from the specified site")
    func test_fetchMixedItems_respects_site_isolation() async throws {
        // Given
        let otherSiteID: Int64 = 456
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
        }
        try await insertProduct(makeProduct(id: 1, name: "Test Our Site", siteID: siteID))
        try await insertProduct(makeProduct(id: 2, name: "Test Other Site", siteID: otherSiteID))
        try await rebuildSearchIndex()
        try await rebuildSearchIndex(for: otherSiteID)
        let strategy = makeStrategy()

        // When
        let result = try #require(await strategy.fetchMixedItems(pageNumber: 1))

        // Then
        #expect(result.items.map(\.id) == [POSItemIdentifier(underlyingType: .product, itemID: 1)])
        #expect(result.totalItems == 1)
    }

    @Test("fetchMixedItems tracks the FTS search method on the first page")
    func test_fetchMixedItems_tracks_fts_search_method() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Test Product"))
        try await rebuildSearchIndex()
        let strategy = makeStrategy()

        // When
        _ = try await strategy.fetchMixedItems(pageNumber: 1)

        // Then
        #expect(mockAnalytics.spyLocalSearchMethod == .fts)
        #expect(mockAnalytics.spyLocalSearchSource == .purchasableItems)
        #expect(mockAnalytics.spyLocalSearchTotalItems == 1)
    }

    // MARK: - Variations Tests

    @Test("fetchVariations returns variations for parent product from local catalog")
    func test_fetchVariations_returns_variations_from_local_catalog() async throws {
        // Given
        let parentProductID: Int64 = 100
        try await insertProduct(makeProduct(id: parentProductID, name: "Variable Product", productTypeKey: "variable"))
        try await insertVariation(makeVariation(id: 1, productID: parentProductID, price: "10.00"))
        try await insertVariation(makeVariation(id: 2, productID: parentProductID, price: "15.00"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 1)

        // Then
        #expect(result.items.count == 2)
        #expect(result.items[0].productVariationID == 1)
        #expect(result.items[1].productVariationID == 2)
        #expect(result.totalItems == 2)
        #expect(result.hasMorePages == false)
    }

    @Test("fetchVariations filters out downloadable variations")
    func test_fetchVariations_filters_out_downloadable_variations() async throws {
        // Given
        let parentProductID: Int64 = 100
        try await insertProduct(makeProduct(id: parentProductID, name: "Variable Product", productTypeKey: "variable"))
        try await insertVariation(makeVariation(id: 1, productID: parentProductID, downloadable: false))
        try await insertVariation(makeVariation(id: 2, productID: parentProductID, downloadable: true))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.productVariationID == 1)
        #expect(result.items.first?.downloadable == false)
    }

    @Test("fetchVariations returns empty result when no variations")
    func test_fetchVariations_returns_empty_when_no_variations() async throws {
        // Given
        let parentProductID: Int64 = 100
        try await insertProduct(makeProduct(id: parentProductID, name: "Simple Product", productTypeKey: "simple"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 1)

        // Then
        #expect(result.items.isEmpty)
        #expect(result.totalItems == 0)
        #expect(result.hasMorePages == false)
    }

    @Test("fetchVariations handles pagination correctly")
    func test_fetchVariations_handles_pagination_correctly() async throws {
        // Given
        let parentProductID: Int64 = 100
        try await insertProduct(makeProduct(id: parentProductID, name: "Variable Product", productTypeKey: "variable"))

        // Insert 30 variations
        for i in 1...30 {
            try await insertVariation(makeVariation(id: Int64(i), productID: parentProductID, price: "\(i).00"))
        }

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics,
            pageSize: 10
        )

        // When
        let page1 = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 1)
        let page2 = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 2)
        let page3 = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 3)
        let page4 = try await strategy.fetchVariations(parentProductID: parentProductID, pageNumber: 4)

        // Then
        #expect(page1.items.count == 10)
        #expect(page1.hasMorePages == true)
        #expect(page1.totalItems == 30)

        #expect(page2.items.count == 10)
        #expect(page2.hasMorePages == true)
        #expect(page2.totalItems == 30)

        #expect(page3.items.count == 10)
        #expect(page3.hasMorePages == false)
        #expect(page3.totalItems == 30)

        #expect(page4.items.isEmpty)
        #expect(page4.hasMorePages == false)
        #expect(page4.totalItems == 30)
    }

    @Test("fetchVariations only returns variations for specified parent")
    func test_fetchVariations_respects_parent_product_isolation() async throws {
        // Given
        let parentProduct1ID: Int64 = 100
        let parentProduct2ID: Int64 = 200
        try await insertProduct(makeProduct(id: parentProduct1ID, name: "Variable Product 1", productTypeKey: "variable"))
        try await insertProduct(makeProduct(id: parentProduct2ID, name: "Variable Product 2", productTypeKey: "variable"))
        try await insertVariation(makeVariation(id: 1, productID: parentProduct1ID))
        try await insertVariation(makeVariation(id: 2, productID: parentProduct2ID))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchVariations(parentProductID: parentProduct1ID, pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.productVariationID == 1)
        #expect(result.items.first?.productID == parentProduct1ID)
    }

    // MARK: - Helper Methods

    private func makeStrategy(searchTerm: String? = nil, pageSize: Int = 25) -> PointOfSaleLocalSearchPurchasableItemFetchStrategy {
        PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm ?? self.searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: itemMapper,
            analytics: mockAnalytics,
            pageSize: pageSize
        )
    }

    private func rebuildSearchIndex(for siteID: Int64? = nil) async throws {
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID ?? self.siteID, in: grdbManager.databaseConnection)
    }

    private func makeProduct(
        id: Int64,
        name: String,
        siteID: Int64? = nil,
        productTypeKey: String = "simple",
        sku: String? = nil,
        globalUniqueID: String? = nil,
        downloadable: Bool = false
    ) -> PersistedProduct {
        PersistedProduct(
            id: id,
            siteID: siteID ?? self.siteID,
            name: name,
            productTypeKey: productTypeKey,
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: "10.00",
            downloadable: downloadable,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
    }

    private func insertProduct(_ product: PersistedProduct) async throws {
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }

    private func makeVariation(
        id: Int64,
        productID: Int64,
        siteID: Int64? = nil,
        sku: String? = nil,
        price: String = "10.00",
        downloadable: Bool = false
    ) -> PersistedProductVariation {
        PersistedProductVariation(
            id: id,
            siteID: siteID ?? self.siteID,
            productID: productID,
            sku: sku,
            globalUniqueID: nil,
            price: price,
            downloadable: downloadable,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
    }

    private func insertVariation(_ variation: PersistedProductVariation) async throws {
        try await grdbManager.databaseConnection.write { db in
            try variation.insert(db)
        }
    }
}
