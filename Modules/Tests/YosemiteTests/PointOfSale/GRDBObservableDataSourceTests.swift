import Foundation
import Testing
import Combine
import WooFoundation
@testable import Storage
@testable import Yosemite

@Suite("GRDBObservableDataSource Tests")
struct GRDBObservableDataSourceTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!
    private var sut: GRDBObservableDataSource!

    init() async throws {
        grdbManager = try GRDBManager()

        let siteID = siteID
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }

        sut = GRDBObservableDataSource(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings(),
            pageSize: 5
        )
    }

    @Test("Initial state has empty items and no loading")
    func test_initial_state_has_empty_items_and_no_loading() {
        #expect(sut.productItems.isEmpty)
        #expect(sut.variationItems.isEmpty)
        #expect(sut.isLoadingProducts == false)
        #expect(sut.isLoadingVariations == false)
        #expect(sut.hasMoreProducts == false)
        #expect(sut.hasMoreVariations == false)
        #expect(sut.error == nil)
    }

    @Test("Load products sets loading state and fetches items from database")
    func test_load_products_sets_loading_state_and_fetches_items() async throws {
        // Given: Insert test products into database
        try await insertTestProducts(count: 3)

        // When: Load products
        await waitForProductLoad {
            sut.loadProducts()
        }

        // Then
        #expect(sut.productItems.count == 3)
        #expect(sut.isLoadingProducts == false)
        #expect(sut.error == nil)
    }

    @Test("Load products maps database products to POSItems correctly")
    func test_load_products_maps_to_pos_items_correctly() async throws {
        // Given: Insert a simple and variable product
        let simpleProduct = createPersistedProduct(id: 1, name: "Simple Product", type: "simple")
        let variableProduct = createPersistedProduct(id: 2, name: "Variable Product", type: "variable")
        try await insertProducts([simpleProduct, variableProduct])

        // When: Load products
        await waitForProductLoad {
            sut.loadProducts()
        }

        // Then: Verify correct mapping
        #expect(sut.productItems.count == 2)

        guard case .simpleProduct(let simple) = sut.productItems[0] else {
            Issue.record("First item should be simple product")
            return
        }
        #expect(simple.name == "Simple Product")

        guard case .variableParentProduct(let variable) = sut.productItems[1] else {
            Issue.record("Second item should be variable product")
            return
        }
        #expect(variable.name == "Variable Product")
    }

    @Test("Load more products paginates correctly")
    func test_load_more_products_paginates_correctly() async throws {
        // Given: Insert 8 products with page size of 5
        try await insertTestProducts(count: 8)

        // When: Load first page
        await waitForProductLoad {
            sut.loadProducts()
        }

        // Then: First page loaded
        #expect(sut.productItems.count == 5)
        #expect(sut.hasMoreProducts == true)

        // When: Load more
        await waitForProductLoad {
            sut.loadMoreProducts()
        }

        // Then: Both pages loaded
        #expect(sut.productItems.count == 8)
        #expect(sut.hasMoreProducts == false)
    }

    @Test("Load variations for parent product")
    func test_load_variations_for_parent_product() async throws {
        // Given: Insert parent product and variations
        let parentProduct = createPersistedProduct(id: 100, name: "Parent", type: "variable")
        try await insertProducts([parentProduct])
        try await insertTestVariations(parentID: 100, count: 3)

        let posParent = POSVariableParentProduct(
            id: UUID(),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )

        // When: Load variations
        await waitForVariationLoad {
            sut.loadVariations(for: posParent)
        }

        // Then: Variations loaded
        #expect(sut.variationItems.count == 3)
        #expect(sut.isLoadingVariations == false)
        #expect(sut.productItems.isEmpty) // Products should remain unaffected
    }

    @Test("Load variations is idempotent for same parent")
    func test_load_variations_is_idempotent_for_same_parent() async throws {
        // Given: Parent with variations
        let parentProduct = createPersistedProduct(id: 100, name: "Parent", type: "variable")
        try await insertProducts([parentProduct])
        try await insertTestVariations(parentID: 100, count: 2)

        let posParent = POSVariableParentProduct(
            id: UUID(),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )

        // When: Load variations first time
        await waitForVariationLoad {
            sut.loadVariations(for: posParent)
        }
        let firstCount = sut.variationItems.count

        // When: Load variations second time (should be idempotent)
        let isLoadingBefore = sut.isLoadingVariations
        sut.loadVariations(for: posParent)
        let isLoadingAfter = sut.isLoadingVariations

        // Then: Should not trigger a new load
        #expect(firstCount == 2)
        #expect(isLoadingBefore == false)
        #expect(isLoadingAfter == false)
    }

    @Test("Load variations resets when parent changes")
    func test_load_variations_resets_when_parent_changes() async throws {
        // Given: Two parents with different variations
        let parent1 = createPersistedProduct(id: 100, name: "Parent 1", type: "variable")
        let parent2 = createPersistedProduct(id: 200, name: "Parent 2", type: "variable")
        try await insertProducts([parent1, parent2])
        try await insertTestVariations(parentID: 100, count: 2)
        try await insertTestVariations(parentID: 200, count: 3)

        let posParent1 = POSVariableParentProduct(id: UUID(), name: "Parent 1", productImageSource: nil, productID: 100, allAttributes: [])
        let posParent2 = POSVariableParentProduct(id: UUID(), name: "Parent 2", productImageSource: nil, productID: 200, allAttributes: [])

        // When: Load parent 1 variations
        await waitForVariationLoad {
            sut.loadVariations(for: posParent1)
        }
        #expect(sut.variationItems.count == 2)

        // When: Load parent 2 variations
        await waitForVariationLoad {
            sut.loadVariations(for: posParent2)
        }

        // Then: Should show parent 2 variations
        #expect(sut.variationItems.count == 3)
    }

    @Test("Database observation updates items automatically")
    func test_database_observation_updates_items_automatically() async throws {
        // Given: Initial products loaded
        try await insertTestProducts(count: 2)
        await waitForProductLoad {
            sut.loadProducts()
        }
        #expect(sut.productItems.count == 2)

        // When: Insert new product and wait for observation update
        try await waitForProductChange(expectedCount: 3) {
            try await insertTestProducts(count: 1, startID: 100)
        }

        // Then: Items automatically updated
        #expect(sut.productItems.count == 3)
    }

    @Test("Refresh is a no-op")
    func test_refresh_is_a_no_op() {
        // When/Then: Should not crash or change state
        sut.refresh()
        #expect(sut.productItems.isEmpty)
        #expect(sut.isLoadingProducts == false)
    }

    @Test("Load more products guards against concurrent loads")
    func test_load_more_products_guards_against_concurrent_loads() async throws {
        // Given: Products already loaded
        try await insertTestProducts(count: 20)
        await waitForProductLoad {
            sut.loadProducts()
        }

        // When: Try to load more while simulating loading state
        let canLoadMore = sut.hasMoreProducts && !sut.isLoadingProducts
        #expect(canLoadMore == true)

        // Trigger load more
        await waitForProductLoad {
            sut.loadMoreProducts()
        }

        // Then: Should have loaded second page
        #expect(sut.productItems.count == 10) // 2 pages of 5
    }

    @Test("Load more variations guards when no parent set")
    func test_load_more_variations_guards_when_no_parent_set() {
        // When: Try to load more without setting parent first
        sut.loadMoreVariations()

        // Then: Should not crash or change state
        #expect(sut.variationItems.isEmpty)
        #expect(sut.isLoadingVariations == false)
    }

    @Test("Products and variations are independent")
    func test_products_and_variations_are_independent() async throws {
        // Given: Products and variations in database
        try await insertTestProducts(count: 3)
        let parent = createPersistedProduct(id: 100, name: "Parent", type: "variable")
        try await insertProducts([parent])
        try await insertTestVariations(parentID: 100, count: 2)

        // When: Load products
        await waitForProductLoad {
            sut.loadProducts()
        }
        #expect(sut.productItems.count == 4)
        #expect(sut.variationItems.isEmpty)

        // When: Load variations
        let posParent = POSVariableParentProduct(id: UUID(), name: "Parent", productImageSource: nil, productID: 100, allAttributes: [])
        await waitForVariationLoad {
            sut.loadVariations(for: posParent)
        }

        // Then: Both arrays populated independently
        #expect(sut.productItems.count == 4)
        #expect(sut.variationItems.count == 2)
    }

    // MARK: - Helper Methods

    private func waitForProductLoad(action: () -> Void) async {
        action()
        // Wait for observation to complete
        for _ in 0..<50 { // Max 500ms
            if !sut.isLoadingProducts {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    private func waitForVariationLoad(action: () -> Void) async {
        action()
        // Wait for observation to complete
        for _ in 0..<50 { // Max 500ms
            if !sut.isLoadingVariations {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    private func waitForProductChange(expectedCount: Int, action: () async throws -> Void) async rethrows {
        try await action()
        // Wait for observation to complete
        for _ in 0..<50 { // Max 500ms
            if sut.productItems.count == expectedCount {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    private func insertTestProducts(count: Int, startID: Int64 = 1) async throws {
        let products = (0..<count).map { index in
            createPersistedProduct(id: startID + Int64(index), name: "Product \(startID + Int64(index))", type: "simple")
        }
        try await insertProducts(products)
    }

    private func insertProducts(_ products: [PersistedProduct]) async throws {
        try await grdbManager.databaseConnection.write { db in
            for product in products {
                try product.insert(db)
            }
        }
    }

    private func insertTestVariations(parentID: Int64, count: Int) async throws {
        try await grdbManager.databaseConnection.write { db in
            for index in 0..<count {
                let variation = PersistedProductVariation(
                    id: parentID * 1000 + Int64(index),
                    siteID: siteID,
                    productID: parentID,
                    sku: nil,
                    globalUniqueID: nil,
                    price: "10.00",
                    downloadable: false,
                    fullDescription: nil,
                    manageStock: false,
                    stockQuantity: nil,
                    stockStatusKey: "instock"
                )
                try variation.insert(db)
            }
        }
    }

    private func createPersistedProduct(id: Int64, name: String, type: String) -> PersistedProduct {
        PersistedProduct(
            id: id,
            siteID: siteID,
            name: name,
            productTypeKey: type,
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
    }
}
