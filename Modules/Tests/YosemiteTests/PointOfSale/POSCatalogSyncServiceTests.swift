import Testing
@testable import Networking
@testable import Yosemite
@testable import Storage

struct POSCatalogSyncServiceTests {
    private var sut: POSCatalogSyncService!
    private var mockNetwork: MockNetwork!
    private var mockStorageManager: MockStorageManager!
    private var mockDispatcher: Dispatcher!
    private let siteID: Int64 = 123

    @MainActor
    init() {
        mockNetwork = MockNetwork()
        mockStorageManager = MockStorageManager()
        mockDispatcher = Dispatcher()
        sut = POSCatalogSyncService(
            siteID: siteID,
            network: mockNetwork,
            storageManager: mockStorageManager,
            dispatcher: mockDispatcher
        )
    }

    /// Helper to create file-based storage manager for tests that need batch operations
    @MainActor
    private func createFileBasedSUT() -> POSCatalogSyncService {
        let fileBasedStorageManager = MockStorageManager(useFileBasedStore: true)
        return POSCatalogSyncService(
            siteID: siteID,
            network: mockNetwork,
            storageManager: fileBasedStorageManager,
            dispatcher: mockDispatcher
        )
    }

    // MARK: - Success Tests

    // Commented out for now as the large json is cluttering diffs
//    @Test func syncCatalog_with_large_dataset_processes_in_batches_and_stores_all() async throws {
//        // Given
//        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-large")
//
//        // When
//        try await sut.syncCatalog()
//
//        // Then - Verify products were stored (check a few samples)
//        let firstProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 1))
//        #expect(firstProduct.name == "Product 1")
//        #expect(firstProduct.sku == "PROD-001")
//
//        let middleProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 125))
//        #expect(middleProduct.name == "Product 125")
//
//        let lastProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 249))
//        #expect(lastProduct.name == "Product 249")
//
//        // Verify some variations were stored (every 10th item is a variation)
//        let variation10 = try #require(mockStorageManager.viewStorage.loadProductVariation(siteID: siteID, productVariationID: 10))
//        #expect(variation10.productID == 9) // parent_id should be i-1
//
//        let variation20 = try #require(mockStorageManager.viewStorage.loadProductVariation(siteID: siteID, productVariationID: 20))
//        #expect(variation20.productID == 19)
//
//        // Verify total counts - should have ~225 products and ~25 variations
//        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
//        #expect(allStoredProducts.count > 200) // Should have stored most products
//
//        // Check that variations exist for their parent products
//        let variationsForProduct9 = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 9) ?? []
//        #expect(variationsForProduct9.count > 0)
//    }

    @Test func syncCatalog_with_empty_json_array_succeeds_and_stores_nothing() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-empty")

        // When
        try await sut.syncCatalog()

        // Then - Verify no products were stored
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.isEmpty)
    }

    // MARK: - Error Tests

    @Test func syncCatalog_with_network_error_throws_correct_error() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateError(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", error: NetworkError.notFound())

        // When & Then
        await #expect(throws: NetworkError.notFound(response: nil)) {
            try await sut.syncCatalog()
        }

        // Verify no products were stored due to the error
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.isEmpty)
    }

    @Test func syncCatalog_with_invalid_json_throws_invalidData_error() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-invalid")

        // When & Then
        var thrownError: Error?
        do {
            try await sut.syncCatalog()
            #expect(Bool(false), "Expected DecodingError to be thrown")
        } catch {
            thrownError = error
        }

        // Verify it's a DecodingError.dataCorrupted
        guard let decodingError = thrownError as? DecodingError else {
            #expect(Bool(false), "Expected DecodingError but got \(type(of: thrownError))")
            return
        }

        if case .dataCorrupted = decodingError {
            // Success - it's the expected error type
        } else {
            #expect(Bool(false), "Expected DecodingError.dataCorrupted but got \(decodingError)")
        }

        // Verify no products were stored due to the parsing error
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.isEmpty)
    }

    // MARK: - Product Deletion and Insertion Tests

    // TODO-jc: fix test case
    @MainActor
    @Test func syncCatalog_replaces_existing_products_during_sync() async throws {
        // Use file-based storage for batch operations
        let fileBasedStorageManager = MockStorageManager(useFileBasedStore: true)
        let fileBasedSUT = POSCatalogSyncService(
            siteID: siteID,
            network: mockNetwork,
            storageManager: fileBasedStorageManager,
            dispatcher: Dispatcher()
        )

        // Given - First, populate storage with initial products
        await fileBasedStorageManager.performAndSaveAsync { storage in
            let product1 = storage.insertNewObject(ofType: Storage.Product.self)
            product1.siteID = self.siteID
            product1.productID = 999
            product1.name = "Old Product 1"
            product1.sku = "OLD-001"
            product1.statusKey = "publish"

            let product2 = storage.insertNewObject(ofType: Storage.Product.self)
            product2.siteID = self.siteID
            product2.productID = 998
            product2.name = "Old Product 2"
            product2.sku = "OLD-002"
            product2.statusKey = "publish"
        }

        // Verify initial products exist - with debug info
        var storedProducts = fileBasedStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        print("🔍 Initial products count: \(storedProducts.count)")
        for product in storedProducts {
            print("🔍 Initial product: ID=\(product.productID), siteID=\(product.siteID), name=\(product.name)")
        }
        #expect(storedProducts.count == 2)
        #expect(storedProducts.contains { $0.productID == 999 && $0.siteID == siteID })
        #expect(storedProducts.contains { $0.productID == 998 })

        // When - Sync new catalog (should replace all existing products)
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-valid")
        try await fileBasedSUT.syncCatalog()

        // Then - Verify old products are deleted and new product is inserted - with debug info
        storedProducts = fileBasedStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        print("🔍 Final products count: \(storedProducts.count)")
        for product in storedProducts {
            print("🔍 Final product: ID=\(product.productID), siteID=\(product.siteID), name=\(product.name)")
        }

        // First check if batch delete worked at all
        let oldProductsStillExist = storedProducts.contains { $0.productID == 999 || $0.productID == 998 }
        if oldProductsStillExist {
            print("⚠️ Old products still exist after sync - batch delete may have failed")
            print("⚠️ This suggests the NSBatchDeleteRequest is not working properly with the current Core Data setup")
        }

        // Check if new product was inserted
        let newProductExists = storedProducts.contains { $0.productID == 123 }
        if !newProductExists {
            print("⚠️ New product was not inserted - batch insert may have failed")
        }

        #expect(storedProducts.count == 1)
        #expect(storedProducts.first?.productID == 123) // From pos-catalog-valid
        #expect(storedProducts.first?.name == "Test Product")

        // Verify old products no longer exist
        #expect(!storedProducts.contains { $0.productID == 999 })
        #expect(!storedProducts.contains { $0.productID == 998 })
    }

    @Test func syncCatalog_deletes_products_from_current_site_only() async throws {
        let otherSiteID: Int64 = 456

        // Given - Add products for current site and another site
        await mockStorageManager.performAndSaveAsync { storage in
            // Products for current site
            let currentSiteProduct = storage.insertNewObject(ofType: Storage.Product.self)
            currentSiteProduct.siteID = self.siteID
            currentSiteProduct.productID = 100
            currentSiteProduct.name = "Current Site Product"

            // Products for different site
            let otherSiteProduct = storage.insertNewObject(ofType: Storage.Product.self)
            otherSiteProduct.siteID = otherSiteID
            otherSiteProduct.productID = 200
            otherSiteProduct.name = "Other Site Product"
        }

        // Verify initial state
        var currentSiteProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        var otherSiteProducts = mockStorageManager.viewStorage.loadProducts(siteID: otherSiteID) ?? []
        #expect(currentSiteProducts.count == 1)
        #expect(otherSiteProducts.count == 1)

        // When - Sync catalog for current site
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-valid")
        try await sut.syncCatalog()

        // Then - Verify only current site products are replaced
        currentSiteProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        otherSiteProducts = mockStorageManager.viewStorage.loadProducts(siteID: otherSiteID) ?? []

        #expect(currentSiteProducts.count == 1)
        #expect(currentSiteProducts.first?.productID == 123) // New product from sync
        #expect(otherSiteProducts.count == 1) // Other site products unchanged
        #expect(otherSiteProducts.first?.productID == 200)
    }

    @Test func syncCatalog_cascades_deletion_to_variations() async throws {
        // Given - Add product with variations
        await mockStorageManager.performAndSaveAsync { storage in
            let product = storage.insertNewObject(ofType: Storage.Product.self)
            product.siteID = self.siteID
            product.productID = 100
            product.name = "Variable Product"

            let variation1 = storage.insertNewObject(ofType: Storage.ProductVariation.self)
            variation1.siteID = self.siteID
            variation1.productID = 100
            variation1.productVariationID = 101
            variation1.sku = "VAR-001"

            let variation2 = storage.insertNewObject(ofType: Storage.ProductVariation.self)
            variation2.siteID = self.siteID
            variation2.productID = 100
            variation2.productVariationID = 102
            variation2.sku = "VAR-002"
        }

        // Verify initial state
        var storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        var storedVariations = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 100) ?? []
        #expect(storedProducts.count == 1)
        #expect(storedVariations.count == 2)

        // When - Sync new catalog (should delete product and its variations)
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-valid")
        try await sut.syncCatalog()

        // Then - Verify product and variations are deleted
        storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        storedVariations = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 100) ?? []

        #expect(storedProducts.count == 1)
        #expect(storedProducts.first?.productID == 123) // New product from sync
        #expect(storedVariations.isEmpty) // All old variations should be deleted
    }

    @Test func syncCatalog_inserts_new_products_and_variations_correctly() async throws {
        // Given - Empty storage
        let initialProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(initialProducts.isEmpty)

        // When - Sync catalog with mixed products and variations
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-mixed")
        try await sut.syncCatalog()

        // Then - Verify both products and variations are inserted
        let storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(storedProducts.count == 1)
        let storedProduct = try #require(storedProducts.first)
        #expect(storedProduct.productID == 123)
        #expect(storedProduct.name == "Incredible Silk Chair")
        #expect(storedProduct.sku == "incredible-silk-chair-13060312")
        #expect(storedProduct.globalUniqueID == "0019273")
        #expect(storedProduct.stockQuantity == "-83")
        #expect(storedProduct.attributes?.count == 3)

        let storedVariations = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 123) ?? []
        #expect(storedVariations.count == 1)
        let storedVariation = try #require(storedVariations.first)
        #expect(storedVariation.productVariationID == 124)
        #expect(storedVariation.productID == 123)
        #expect(storedVariation.product == storedProduct) // Ensure relationship is set
        #expect(storedVariation.sku == "TEST-32-VAR")
        #expect(storedVariation.price == "330.34")
        #expect(storedVariation.stockQuantity == 69)
        #expect(storedVariation.attributes.count == 3)
    }

    @Test func syncCatalog_handles_multiple_sync_cycles_correctly() async throws {
        // Given - Start with empty storage
        var storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(storedProducts.isEmpty)

        // When - First sync
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-valid")
        try await sut.syncCatalog()

        // Then - Verify first sync results
        storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(storedProducts.count == 1)
        #expect(storedProducts.first?.productID == 123)

        // When - Second sync with different data
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-mixed")
        try await sut.syncCatalog()

        // Then - Verify second sync replaced first sync data
        storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        let storedVariations = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 123) ?? []

        #expect(storedProducts.count == 1)
        #expect(storedProducts.first?.productID == 123)
        #expect(storedVariations.count == 1) // Variation should now exist

        // When - Third sync with empty catalog
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-response")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/status/export_1755754737_9171", filename: "pos-catalog-status-complete")
        mockNetwork.simulateResponse(requestUrlSuffix: "catalog/download?filename=pos-catalog&format=json", filename: "pos-catalog-empty")
        try await sut.syncCatalog()

        // Then - Verify all data is cleared
        storedProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(storedProducts.isEmpty)
    }
}
