import Foundation
import Testing
import Networking
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

    init() async throws {
        grdbManager = try GRDBManager()

        // Initialize site
        let siteIDLocalCopy = self.siteID
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteIDLocalCopy).insert(db)
        }
    }

    // MARK: - Search Functionality Tests

    @Test("fetchProducts returns matching products")
    func test_fetchProducts_returns_matching_products() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Test Product"))
        try await insertProduct(makeProduct(id: 2, name: "Another Product"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.name == "Test Product")
        #expect(result.totalItems == 1)
    }

    @Test("fetchProducts searches by SKU")
    func test_fetchProducts_searches_by_sku() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Product A", sku: "TEST-SKU-123"))
        try await insertProduct(makeProduct(id: 2, name: "Product B", sku: "OTHER-SKU-456"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: "TEST-SKU",
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.sku == "TEST-SKU-123")
    }

    @Test("fetchProducts searches by global unique ID")
    func test_fetchProducts_searches_by_global_unique_id() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Product A", globalUniqueID: "1234567890"))
        try await insertProduct(makeProduct(id: 2, name: "Product B", globalUniqueID: "0987654321"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: "12345",
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.globalUniqueID == "1234567890")
    }

    @Test("fetchProducts returns empty result when no matches")
    func test_fetchProducts_returns_empty_when_no_matches() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Coffee"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: "nonexistent",
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.isEmpty)
        #expect(result.totalItems == 0)
        #expect(result.hasMorePages == false)
    }

    // MARK: - Pagination Tests

    @Test("fetchProducts handles pagination correctly")
    func test_fetchProducts_handles_pagination_correctly() async throws {
        // Given - insert 30 products
        for i in 1...30 {
            try await insertProduct(makeProduct(id: Int64(i), name: "Test Product \(i)"))
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
        let page1 = try await strategy.fetchProducts(pageNumber: 1)
        let page2 = try await strategy.fetchProducts(pageNumber: 2)
        let page3 = try await strategy.fetchProducts(pageNumber: 3)
        let page4 = try await strategy.fetchProducts(pageNumber: 4)

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

    @Test("fetchProducts hasMorePages is false when exactly one page")
    func test_fetchProducts_hasMorePages_false_when_exactly_one_page() async throws {
        // Given - insert exactly 25 products (default page size)
        for i in 1...25 {
            try await insertProduct(makeProduct(id: Int64(i), name: "Test Product \(i)"))
        }

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics,
            pageSize: 25
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 25)
        #expect(result.hasMorePages == false)
        #expect(result.totalItems == 25)
    }

    @Test("fetchProducts hasMorePages is true when more than one page")
    func test_fetchProducts_hasMorePages_true_when_more_than_one_page() async throws {
        // Given - insert 26 products (one more than page size)
        for i in 1...26 {
            try await insertProduct(makeProduct(id: Int64(i), name: "Test Product \(i)"))
        }

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics,
            pageSize: 25
        )

        // When
        let page1 = try await strategy.fetchProducts(pageNumber: 1)
        let page2 = try await strategy.fetchProducts(pageNumber: 2)

        // Then
        #expect(page1.items.count == 25)
        #expect(page1.hasMorePages == true)

        #expect(page2.items.count == 1)
        #expect(page2.hasMorePages == false)
    }

    // MARK: - Filtering Tests

    @Test("fetchProducts filters out downloadable products")
    func test_fetchProducts_filters_out_downloadable_products() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Test Physical", downloadable: false))
        try await insertProduct(makeProduct(id: 2, name: "Test Digital", downloadable: true))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.name == "Test Physical")
        #expect(result.items.first?.downloadable == false)
    }

    @Test("fetchProducts only returns simple and variable products")
    func test_fetchProducts_only_returns_pos_supported_types() async throws {
        // Given
        try await insertProduct(makeProduct(id: 1, name: "Test Simple", productTypeKey: "simple"))
        try await insertProduct(makeProduct(id: 2, name: "Test Variable", productTypeKey: "variable"))
        try await insertProduct(makeProduct(id: 3, name: "Test Grouped", productTypeKey: "grouped"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 2)
        #expect(result.items.contains(where: { $0.productTypeKey == "simple" }))
        #expect(result.items.contains(where: { $0.productTypeKey == "variable" }))
        #expect(!result.items.contains(where: { $0.productTypeKey == "grouped" }))
    }

    // MARK: - Site Isolation Tests

    @Test("fetchProducts only returns products from specified site")
    func test_fetchProducts_respects_site_isolation() async throws {
        // Given
        let otherSiteID: Int64 = 456

        // Insert other site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
        }

        try await insertProduct(makeProduct(id: 1, name: "Test Our Site", siteID: siteID))
        try await insertProduct(makeProduct(id: 2, name: "Test Other Site", siteID: otherSiteID))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 1)
        #expect(result.items.first?.siteID == siteID)
        #expect(result.items.first?.name == "Test Our Site")
    }

    // MARK: - Sorting Tests

    @Test("fetchProducts returns results sorted by name")
    func test_fetchProducts_returns_results_sorted_by_name() async throws {
        // Given - insert in non-alphabetical order
        try await insertProduct(makeProduct(id: 1, name: "Test Zebra"))
        try await insertProduct(makeProduct(id: 2, name: "Test Alpha"))
        try await insertProduct(makeProduct(id: 3, name: "Test Beta"))

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: searchTerm,
            grdbManager: grdbManager,
            variationsRemote: variationsRemote,
            itemMapper: mockItemMapper,
            analytics: mockAnalytics
        )

        // When
        let result = try await strategy.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.items.count == 3)
        #expect(result.items[0].name == "Test Alpha")
        #expect(result.items[1].name == "Test Beta")
        #expect(result.items[2].name == "Test Zebra")
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
