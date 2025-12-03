import Foundation
import Testing
@testable import Storage

@Suite("PersistedProduct Search Query Tests")
struct PersistedProductSearchQueryTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!

    init() async throws {
        grdbManager = try GRDBManager()

        // Initialize site
        let siteID = siteID
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }
    }

    // MARK: - Basic Search Tests

    @Test("posProductSearch finds product by name")
    func test_finds_product_by_name() async throws {
        // Given
        let product = PersistedProduct(
            id: 1,
            siteID: siteID,
            name: "Coffee Mug",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "MUG-001",
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Coffee").fetchAll(db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.id == 1)
        #expect(results.first?.name == "Coffee Mug")
    }

    @Test("posProductSearch finds product by SKU")
    func test_finds_product_by_sku() async throws {
        // Given
        let product = PersistedProduct(
            id: 2,
            siteID: siteID,
            name: "Test Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "ABC-123",
            globalUniqueID: nil,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "ABC").fetchAll(db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.sku == "ABC-123")
    }

    @Test("posProductSearch finds product by global unique ID")
    func test_finds_product_by_global_unique_id() async throws {
        // Given
        let product = PersistedProduct(
            id: 3,
            siteID: siteID,
            name: "Barcode Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: "1234567890",
            price: "30.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "12345").fetchAll(db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.globalUniqueID == "1234567890")
    }

    // MARK: - Case Insensitive Search Tests

    @Test("posProductSearch is case insensitive")
    func test_search_is_case_insensitive() async throws {
        // Given
        let product = PersistedProduct(
            id: 4,
            siteID: siteID,
            name: "Blue Shirt",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "SHIRT-BLUE",
            globalUniqueID: nil,
            price: "25.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When - search with different cases
        let lowerCaseResults = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "blue").fetchAll(db)
        }
        let upperCaseResults = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "BLUE").fetchAll(db)
        }
        let mixedCaseResults = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "BLuE").fetchAll(db)
        }

        // Then
        #expect(lowerCaseResults.count == 1)
        #expect(upperCaseResults.count == 1)
        #expect(mixedCaseResults.count == 1)
    }

    // MARK: - Partial Match Tests

    @Test("posProductSearch matches partial terms")
    func test_search_matches_partial_terms() async throws {
        // Given
        let product = PersistedProduct(
            id: 5,
            siteID: siteID,
            name: "Ergonomic Keyboard",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "KB-ERG-001",
            globalUniqueID: nil,
            price: "75.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "nomic").fetchAll(db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.name == "Ergonomic Keyboard")
    }

    // MARK: - Multiple Results Tests

    @Test("posProductSearch returns multiple matching products")
    func test_search_returns_multiple_matches() async throws {
        // Given
        let products = [
            PersistedProduct(id: 6, siteID: siteID, name: "Coffee Beans", productTypeKey: "simple",
                           fullDescription: nil, shortDescription: nil, sku: nil, globalUniqueID: nil,
                           price: "15.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish"),
            PersistedProduct(id: 7, siteID: siteID, name: "Coffee Grinder", productTypeKey: "simple",
                           fullDescription: nil, shortDescription: nil, sku: nil, globalUniqueID: nil,
                           price: "45.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish"),
            PersistedProduct(id: 8, siteID: siteID, name: "Coffee Maker", productTypeKey: "variable",
                           fullDescription: nil, shortDescription: nil, sku: nil, globalUniqueID: nil,
                           price: "100.00", downloadable: false, parentID: 0, manageStock: false,
                             stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish"),
            PersistedProduct(id: 9, siteID: siteID, name: "Tea Strainer", productTypeKey: "variable",
                           fullDescription: nil, shortDescription: nil, sku: nil, globalUniqueID: nil,
                           price: "5.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish")
        ]
        for product in products {
            try await insertProduct(product)
        }

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Coffee").fetchAll(db)
        }

        // Then
        #expect(results.count == 3)
    }

    // MARK: - Filtering Tests

    @Test("posProductSearch filters out downloadable products")
    func test_search_filters_out_downloadable_products() async throws {
        // Given
        let downloadableProduct = PersistedProduct(
            id: 9,
            siteID: siteID,
            name: "Digital Download",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: true,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(downloadableProduct)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Digital").fetchAll(db)
        }

        // Then
        #expect(results.isEmpty)
    }

    @Test("posProductSearch only returns simple and variable product types")
    func test_search_only_returns_pos_supported_product_types() async throws {
        // Given
        let simpleProduct = PersistedProduct(
            id: 10,
            siteID: siteID,
            name: "Search Test Simple",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        let variableProduct = PersistedProduct(
            id: 11,
            siteID: siteID,
            name: "Search Test Variable",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        let groupedProduct = PersistedProduct(
            id: 12,
            siteID: siteID,
            name: "Search Test Grouped",
            productTypeKey: "grouped",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(simpleProduct)
        try await insertProduct(variableProduct)
        try await insertProduct(groupedProduct)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Search Test").fetchAll(db)
        }

        // Then
        #expect(results.count == 2)
        #expect(results.contains(where: { $0.productTypeKey == "simple" }))
        #expect(results.contains(where: { $0.productTypeKey == "variable" }))
        #expect(!results.contains(where: { $0.productTypeKey == "grouped" }))
    }

    @Test("posProductSearch filters out unsupported product statuses")
    func test_search_only_returns_pos_supported_product_statuses() async throws {
        // Given
        let trashedProduct = PersistedProduct(
            id: 10,
            siteID: siteID,
            name: "Search Test Trash",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "trash"
        )
        let draftProduct = PersistedProduct(
            id: 11,
            siteID: siteID,
            name: "Search Test Draft",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "draft"
        )
        let pendingProduct = PersistedProduct(
            id: 12,
            siteID: siteID,
            name: "Search Test Pending",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "pending"
        )
        let publishedProduct = PersistedProduct(
            id: 13,
            siteID: siteID,
            name: "Search Test Published",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        let privateProduct = PersistedProduct(
            id: 14,
            siteID: siteID,
            name: "Search Test Private",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "private"
        )
        try await insertProduct(trashedProduct)
        try await insertProduct(draftProduct)
        try await insertProduct(pendingProduct)
        try await insertProduct(publishedProduct)
        try await insertProduct(privateProduct)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Search Test").fetchAll(db)
        }

        // Then
        #expect(results.count == 2)
        #expect(results.contains(where: { $0.statusKey == "publish" }))
        #expect(results.contains(where: { $0.statusKey == "private" }))
        #expect(!results.contains(where: { $0.statusKey == "trash" }))
        #expect(!results.contains(where: { $0.statusKey == "draft" }))
        #expect(!results.contains(where: { $0.statusKey == "pending" }))
    }

    // MARK: - Site Isolation Tests

    @Test("posProductSearch only returns products from specified site")
    func test_search_respects_site_isolation() async throws {
        // Given
        let otherSiteID: Int64 = 456

        // Insert other site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
        }

        let ourProduct = PersistedProduct(
            id: 13,
            siteID: siteID,
            name: "Our Site Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "SITE-123",
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        let otherProduct = PersistedProduct(
            id: 14,
            siteID: otherSiteID,
            name: "Other Site Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "SITE-456",
            globalUniqueID: nil,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(ourProduct)
        try await insertProduct(otherProduct)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Site Product").fetchAll(db)
        }

        // Then
        #expect(results.count == 1)
        #expect(results.first?.siteID == siteID)
        #expect(results.first?.id == 13)
    }

    // MARK: - Empty Results Tests

    @Test("posProductSearch returns empty array when no matches")
    func test_search_returns_empty_when_no_matches() async throws {
        // Given
        let product = PersistedProduct(
            id: 15,
            siteID: siteID,
            name: "Example Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "EX-123",
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Nonexistent").fetchAll(db)
        }

        // Then
        #expect(results.isEmpty)
    }

    // MARK: - SQL Escaping Tests

    @Test("posProductSearch handles SQL special characters safely")
    func test_search_handles_sql_special_characters() async throws {
        // Given
        let product = PersistedProduct(
            id: 16,
            siteID: siteID,
            name: "Product 100%",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "100%_OFF",
            globalUniqueID: nil,
            price: "5.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(product)

        // When - search with % and _ (SQL wildcards that should be escaped)
        let percentResults = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "100%").fetchAll(db)
        }
        let underscoreResults = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "100%_").fetchAll(db)
        }

        // Then
        #expect(percentResults.count == 1)
        #expect(percentResults.first?.name == "Product 100%")
        #expect(underscoreResults.count == 1)
        #expect(underscoreResults.first?.sku == "100%_OFF")
    }

    // MARK: - Sorting Tests

    @Test("posProductSearch returns results sorted by name")
    func test_search_returns_results_sorted_by_name() async throws {
        // Given - insert in non-alphabetical order
        let products = [
            PersistedProduct(id: 17, siteID: siteID, name: "Zebra Product", productTypeKey: "simple",
                           fullDescription: nil, shortDescription: nil, sku: "ITEM-Z", globalUniqueID: nil,
                           price: "10.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish"),
            PersistedProduct(id: 18, siteID: siteID, name: "Alpha Product", productTypeKey: "simple",
                           fullDescription: nil, shortDescription: nil, sku: "ITEM-A", globalUniqueID: nil,
                           price: "10.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish"),
            PersistedProduct(id: 19, siteID: siteID, name: "Beta Product", productTypeKey: "simple",
                           fullDescription: nil, shortDescription: nil, sku: "ITEM-B", globalUniqueID: nil,
                           price: "10.00", downloadable: false, parentID: 0, manageStock: false,
                           stockQuantity: nil, stockStatusKey: "instock", statusKey: "publish")
        ]
        for product in products {
            try await insertProduct(product)
        }

        // When
        let results = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductSearch(siteID: siteID, searchTerm: "Product").fetchAll(db)
        }

        // Then
        #expect(results.count == 3)
        #expect(results[0].name == "Alpha Product")
        #expect(results[1].name == "Beta Product")
        #expect(results[2].name == "Zebra Product")
    }

    // MARK: - Helper Methods

    private func insertProduct(_ product: PersistedProduct) async throws {
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }
}
