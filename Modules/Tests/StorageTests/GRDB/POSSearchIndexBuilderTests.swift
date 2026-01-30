import Foundation
import Testing
import GRDB
@testable import Storage

@Suite("POSSearchIndexBuilder Tests")
struct POSSearchIndexBuilderTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!

    init() async throws {
        grdbManager = try GRDBManager()
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: 123).insert(db)
        }
    }

    // MARK: - Helper Methods

    private func insertProduct(
        id: Int64,
        name: String,
        sku: String? = nil,
        productTypeKey: String = "simple",
        downloadable: Bool = false,
        statusKey: String = "publish",
        in db: Database
    ) throws {
        let product = PersistedProduct(
            id: id,
            siteID: siteID,
            name: name,
            productTypeKey: productTypeKey,
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: downloadable,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: statusKey
        )
        try product.insert(db)
    }

    private func insertVariation(
        id: Int64,
        productID: Int64,
        sku: String? = nil,
        downloadable: Bool = false,
        in db: Database
    ) throws {
        let variation = PersistedProductVariation(
            id: id,
            siteID: siteID,
            productID: productID,
            sku: sku,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: downloadable,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try variation.insert(db)
    }

    private func insertVariationAttribute(
        variationID: Int64,
        name: String,
        option: String,
        in db: Database
    ) throws {
        var attribute = PersistedProductVariationAttribute(
            siteID: siteID,
            productVariationID: variationID,
            remoteAttributeID: 1,
            name: name,
            option: option
        )
        try attribute.insert(db)
    }

    // MARK: - rebuildIndex Tests

    @Test("rebuildIndex indexes simple products")
    func test_rebuildIndex_indexes_simple_products() async throws {
        // Given: A simple product in the database
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 100, name: "Simple Widget", sku: "SKU-100", productTypeKey: "simple", in: db)
        }

        // When: Rebuild the index
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: The product is indexed
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Widget", in: db)
        }
        #expect(results.count == 1)
        #expect(results.first?.itemType == .product)
        #expect(results.first?.itemID == 100)
    }

    @Test("rebuildIndex indexes variable products")
    func test_rebuildIndex_indexes_variable_products() async throws {
        // Given: A variable product in the database
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 200, name: "Variable Shirt", sku: "SKU-200", productTypeKey: "variable", in: db)
        }

        // When: Rebuild the index
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: The product is indexed
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Shirt", in: db)
        }
        #expect(results.count == 1)
        #expect(results.first?.itemType == .product)
        #expect(results.first?.itemID == 200)
    }

    @Test("rebuildIndex indexes variations with attributes")
    func test_rebuildIndex_indexes_variations_with_attributes() async throws {
        // Given: A variable product with a variation that has attributes
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 300, name: "T-Shirt", productTypeKey: "variable", in: db)
            try insertVariation(id: 301, productID: 300, sku: "SKU-301", in: db)
            try insertVariationAttribute(variationID: 301, name: "Color", option: "Blue", in: db)
            try insertVariationAttribute(variationID: 301, name: "Size", option: "Large", in: db)
        }

        // When: Rebuild the index
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: The variation is indexed with attributes
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Blue", in: db)
        }
        #expect(results.count == 1)
        #expect(results.first?.itemType == .variation)
        #expect(results.first?.itemID == 301)
        #expect(results.first?.parentProductID == 300)
    }

    @Test("rebuildIndex clears existing index before rebuilding")
    func test_rebuildIndex_clears_existing_index() async throws {
        // Given: An existing index entry
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 400, name: "Old Product", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Verify initial index
        let initialCount = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.searchCount(siteID: siteID, term: "Old", in: db)
        }
        #expect(initialCount == 1)

        // When: Delete the product and rebuild
        try await grdbManager.databaseConnection.write { db in
            try db.execute(sql: "DELETE FROM product WHERE id = 400 AND siteID = ?", arguments: [siteID])
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: The index is cleared
        let finalCount = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.searchCount(siteID: siteID, term: "Old", in: db)
        }
        #expect(finalCount == 0)
    }

    @Test("rebuildIndex excludes downloadable products")
    func test_rebuildIndex_excludes_downloadable_products() async throws {
        // Given: A downloadable product
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 500, name: "Digital Download", productTypeKey: "simple", downloadable: true, in: db)
        }

        // When: Rebuild the index
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: The downloadable product is not indexed
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Digital", in: db)
        }
        #expect(results.isEmpty)
    }

    @Test("rebuildIndex excludes trash/draft/pending products")
    func test_rebuildIndex_excludes_invalid_status_products() async throws {
        // Given: Products with invalid statuses
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 600, name: "Trash Product", productTypeKey: "simple", statusKey: "trash", in: db)
            try insertProduct(id: 601, name: "Draft Product", productTypeKey: "simple", statusKey: "draft", in: db)
            try insertProduct(id: 602, name: "Pending Product", productTypeKey: "simple", statusKey: "pending", in: db)
            try insertProduct(id: 603, name: "Published Product", productTypeKey: "simple", statusKey: "publish", in: db)
        }

        // When: Rebuild the index
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Then: Only the published product is indexed
        let allResults = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Product", in: db)
        }
        #expect(allResults.count == 1)
        #expect(allResults.first?.itemID == 603)
    }

    // MARK: - search Tests

    @Test("search finds products by name")
    func test_search_finds_products_by_name() async throws {
        // Given: A product with a specific name
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 700, name: "Amazing Gadget", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search by name
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Amazing", in: db)
        }

        // Then: The product is found
        #expect(results.count == 1)
        #expect(results.first?.itemID == 700)
    }

    @Test("search finds products by SKU")
    func test_search_finds_products_by_sku() async throws {
        // Given: A product with a specific SKU
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 800, name: "Product", sku: "UNIQUE-SKU-123", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search by SKU
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "UNIQUE-SKU-123", in: db)
        }

        // Then: The product is found
        #expect(results.count == 1)
        #expect(results.first?.itemID == 800)
    }

    @Test("search matches words in any order")
    func test_search_matches_words_in_any_order() async throws {
        // Given: A product with multiple words in name
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 900, name: "Blue Cotton Shirt", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search with words in different order
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Shirt Blue", in: db)
        }

        // Then: The product is found
        #expect(results.count == 1)
        #expect(results.first?.itemID == 900)
    }

    @Test("search uses prefix matching")
    func test_search_uses_prefix_matching() async throws {
        // Given: A product with a specific name
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1000, name: "Comfortable Chair", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search with prefix
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Comf", in: db)
        }

        // Then: The product is found
        #expect(results.count == 1)
        #expect(results.first?.itemID == 1000)
    }

    @Test("search finds variations by attribute")
    func test_search_finds_variations_by_attribute() async throws {
        // Given: A variation with attributes
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1100, name: "Hoodie", productTypeKey: "variable", in: db)
            try insertVariation(id: 1101, productID: 1100, in: db)
            try insertVariationAttribute(variationID: 1101, name: "Color", option: "Crimson", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search by attribute value
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Crimson", in: db)
        }

        // Then: The variation is found
        #expect(results.count == 1)
        #expect(results.first?.itemType == .variation)
        #expect(results.first?.itemID == 1101)
    }

    @Test("search respects limit and offset")
    func test_search_respects_limit_and_offset() async throws {
        // Given: Multiple products
        try await grdbManager.databaseConnection.write { db in
            for i in 1...10 {
                try insertProduct(id: Int64(1200 + i), name: "Test Product \(i)", productTypeKey: "simple", in: db)
            }
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search with limit and offset
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Test", limit: 3, offset: 2, in: db)
        }

        // Then: Only 3 results are returned, skipping first 2
        #expect(results.count == 3)
    }

    // MARK: - searchCount Tests

    @Test("searchCount returns correct total")
    func test_searchCount_returns_correct_total() async throws {
        // Given: Multiple products matching a term
        try await grdbManager.databaseConnection.write { db in
            for i in 1...5 {
                try insertProduct(id: Int64(1300 + i), name: "Matching Item \(i)", productTypeKey: "simple", in: db)
            }
            try insertProduct(id: 1306, name: "Other Thing", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Get search count
        let count = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.searchCount(siteID: siteID, term: "Matching", in: db)
        }

        // Then: Correct count is returned
        #expect(count == 5)
    }

    @Test("search returns empty for no matches")
    func test_search_returns_empty_for_no_matches() async throws {
        // Given: Products that don't match the search term
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1400, name: "Apple", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search for non-matching term
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Banana", in: db)
        }

        // Then: No results
        #expect(results.isEmpty)
    }

    @Test("search only returns results for specified siteID")
    func test_search_only_returns_results_for_specified_siteID() async throws {
        // Given: Products for different sites
        let otherSiteID: Int64 = 456
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
            try insertProduct(id: 1500, name: "Site 123 Product", productTypeKey: "simple", in: db)
            // Insert product for other site
            let otherProduct = PersistedProduct(
                id: 1501,
                siteID: otherSiteID,
                name: "Site 456 Product",
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
            try otherProduct.insert(db)
        }

        // Rebuild for both sites
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)
        try await POSSearchIndexBuilder.rebuildIndex(for: otherSiteID, in: grdbManager.databaseConnection)

        // When: Search for first site
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Product", in: db)
        }

        // Then: Only site 123 product is returned
        #expect(results.count == 1)
        #expect(results.first?.siteID == siteID)
        #expect(results.first?.itemID == 1500)
    }

    @Test("search finds products with hyphenated names using hyphenated query")
    func test_search_finds_products_with_hyphenated_names() async throws {
        // Given: A product with a hyphenated name
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1600, name: "T-Shirt", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search with hyphenated term
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "t-shirt", in: db)
        }

        // Then: The product is found
        #expect(results.count == 1)
        #expect(results.first?.itemID == 1600)
    }

    @Test("search finds products when query contains special characters")
    func test_search_handles_special_characters_in_query() async throws {
        // Given: Products with various names
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1700, name: "Men's T-Shirt", productTypeKey: "simple", in: db)
            try insertProduct(id: 1701, name: "Wi-Fi Router", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Search with apostrophe
        let mensResults = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Men's", in: db)
        }

        // Then: Product is found (apostrophe splits into "Men" and "s")
        #expect(mensResults.count == 1)
        #expect(mensResults.first?.itemID == 1700)

        // When: Search with hyphen
        let wifiResults = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Wi-Fi", in: db)
        }

        // Then: Product is found
        #expect(wifiResults.count == 1)
        #expect(wifiResults.first?.itemID == 1701)
    }

    // MARK: - needsRebuild Tests

    @Test("needsRebuild returns true when products exist but FTS index is empty")
    func test_needsRebuild_returns_true_when_index_empty_but_products_exist() async throws {
        // Given: Products exist but FTS index is empty
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1800, name: "Unindexed Product", productTypeKey: "simple", in: db)
        }
        // Note: rebuildIndex NOT called

        // When: Check if rebuild is needed
        let needsRebuild = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.needsRebuild(for: siteID, in: db)
        }

        // Then: Rebuild is needed
        #expect(needsRebuild == true)
    }

    @Test("needsRebuild returns false when FTS index has entries")
    func test_needsRebuild_returns_false_when_index_populated() async throws {
        // Given: Products exist and FTS index is populated
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 1900, name: "Indexed Product", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // When: Check if rebuild is needed
        let needsRebuild = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.needsRebuild(for: siteID, in: db)
        }

        // Then: Rebuild is not needed
        #expect(needsRebuild == false)
    }

    @Test("needsRebuild returns false when no products exist")
    func test_needsRebuild_returns_false_when_no_products() async throws {
        // Given: No products exist
        // (site exists from init but no products)

        // When: Check if rebuild is needed
        let needsRebuild = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.needsRebuild(for: siteID, in: db)
        }

        // Then: Rebuild is not needed (nothing to index)
        #expect(needsRebuild == false)
    }

    // MARK: - removeFromIndex Tests

    @Test("removeFromIndex removes specific item from FTS index")
    func test_removeFromIndex_removes_specific_item() async throws {
        // Given: Two products in the FTS index
        try await grdbManager.databaseConnection.write { db in
            try insertProduct(id: 2000, name: "Product One", productTypeKey: "simple", in: db)
            try insertProduct(id: 2001, name: "Product Two", productTypeKey: "simple", in: db)
        }
        try await POSSearchIndexBuilder.rebuildIndex(for: siteID, in: grdbManager.databaseConnection)

        // Verify both are searchable
        let beforeResults = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Product", in: db)
        }
        #expect(beforeResults.count == 2)

        // When: Remove one product from index
        try await grdbManager.databaseConnection.write { db in
            try POSSearchIndexBuilder.removeFromIndex(itemID: 2000, itemType: .product, siteID: siteID, in: db)
        }

        // Then: Only the other product is searchable
        let afterResults = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: siteID, term: "Product", in: db)
        }
        #expect(afterResults.count == 1)
        #expect(afterResults.first?.itemID == 2001)
    }
}
