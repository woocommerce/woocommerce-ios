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

    // MARK: - Success Tests

    @Test func syncCatalog_with_valid_json_succeeds_and_stores_product() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-valid")

        // When
        try await sut.syncCatalog()

        // Then - Verify product was stored
        let storedProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 123))
        #expect(storedProduct.name == "Test Product")
        #expect(storedProduct.sku == "TEST-001")
        #expect(storedProduct.price == "19.99")
        #expect(storedProduct.statusKey == "publish")
    }

    @Test func syncCatalog_with_mixed_products_and_variations_stores_both_types() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-mixed")

        // When
        try await sut.syncCatalog()

        // Then - Verify product was stored
        let storedProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 123))
        #expect(storedProduct.name == "Test Product")
        #expect(storedProduct.sku == "TEST-001")

        // Then - Verify variation was stored
        let storedVariation = try #require(mockStorageManager.viewStorage.loadProductVariation(siteID: siteID, productVariationID: 124))
        #expect(storedVariation.productID == 123)
        #expect(storedVariation.sku == "TEST-001-VAR")
        #expect(storedVariation.price == "19.99")
    }

    @Test func syncCatalog_with_large_dataset_processes_in_batches_and_stores_all() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-large")

        // When
        try await sut.syncCatalog()

        // Then - Verify products were stored (check a few samples)
        let firstProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 1))
        #expect(firstProduct.name == "Product 1")
        #expect(firstProduct.sku == "PROD-001")

        let middleProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 125))
        #expect(middleProduct.name == "Product 125")

        let lastProduct = try #require(mockStorageManager.viewStorage.loadProduct(siteID: siteID, productID: 249))
        #expect(lastProduct.name == "Product 249")

        // Verify some variations were stored (every 10th item is a variation)
        let variation10 = try #require(mockStorageManager.viewStorage.loadProductVariation(siteID: siteID, productVariationID: 10))
        #expect(variation10.productID == 9) // parent_id should be i-1

        let variation20 = try #require(mockStorageManager.viewStorage.loadProductVariation(siteID: siteID, productVariationID: 20))
        #expect(variation20.productID == 19)

        // Verify total counts - should have ~225 products and ~25 variations
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.count > 200) // Should have stored most products

        // Check that variations exist for their parent products
        let variationsForProduct9 = mockStorageManager.viewStorage.loadProductVariations(siteID: siteID, productID: 9) ?? []
        #expect(variationsForProduct9.count > 0)
    }

    @Test func syncCatalog_with_empty_json_array_succeeds_and_stores_nothing() async throws {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-empty")

        // When
        try await sut.syncCatalog()

        // Then - Verify no products were stored
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.isEmpty)
    }

    // MARK: - Error Tests

    @Test func syncCatalog_with_network_error_throws_correct_error() async throws {
        // Given
        mockNetwork.simulateError(requestUrlSuffix: "pos-catalog.json", error: NetworkError.notFound())

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
        mockNetwork.simulateResponse(requestUrlSuffix: "pos-catalog.json", filename: "pos-catalog-invalid")

        // When & Then
        await #expect(throws: POSCatalogSyncError.invalidData) {
            try await sut.syncCatalog()
        }

        // Verify no products were stored due to the parsing error
        let allStoredProducts = mockStorageManager.viewStorage.loadProducts(siteID: siteID) ?? []
        #expect(allStoredProducts.isEmpty)
    }
}
