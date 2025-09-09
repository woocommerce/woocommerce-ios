import Foundation
import Testing
@testable import Networking
@testable import Yosemite
@testable import Storage

struct POSCatalogFullSyncServiceTests {
    private let sut: POSCatalogFullSyncService
    private let mockSyncRemote: MockPOSCatalogSyncRemote
    private let mockPersistenceService: MockPOSCatalogPersistenceService
    private let sampleSiteID: Int64 = 134

    init() {
        self.mockSyncRemote = MockPOSCatalogSyncRemote()
        self.mockPersistenceService = MockPOSCatalogPersistenceService()
        self.sut = POSCatalogFullSyncService(syncRemote: mockSyncRemote, batchSize: 2, persistenceService: mockPersistenceService)
    }

    // MARK: - Full Sync Tests

    @Test func startFullSync_loads_products_and_variations() async throws {
        // Given
        let expectedProducts = [POSProduct.fake(), POSProduct.fake()]
        let expectedVariations = [POSProductVariation.fake()]

        mockSyncRemote.setProductResult(pageNumber: 1, result: .success(PagedItems(items: expectedProducts, hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setVariationResult(pageNumber: 1, result: .success(PagedItems(items: expectedVariations, hasMorePages: false, totalItems: 0)))

        // When
        let result = try await sut.startFullSync(for: sampleSiteID)

        // Then
        #expect(result.products.count == expectedProducts.count)
        #expect(result.variations.count == expectedVariations.count)
        #expect(mockSyncRemote.loadProductsCallCount == 2) // 1 batch of 2 requests
        #expect(mockSyncRemote.loadProductVariationsCallCount == 2) // 1 batch of 2 requests
    }

    @Test func startFullSync_handles_paginated_products_correctly() async throws {
        // Given - Multiple pages of products
        let page1Products = [POSProduct.fake()]
        let page2Products = [POSProduct.fake()]
        let page3Products = [POSProduct.fake()]

        mockSyncRemote.setProductResults([
            PagedItems(items: page1Products, hasMorePages: true, totalItems: 3),
            PagedItems(items: page2Products, hasMorePages: true, totalItems: 3),
            PagedItems(items: page3Products, hasMorePages: false, totalItems: 3)
        ])

        // When
        let result = try await sut.startFullSync(for: sampleSiteID)

        // Then
        #expect(result.products.count == 3)
        #expect(mockSyncRemote.loadProductsCallCount == 4) // 2 batches of 2 requests
        #expect(mockSyncRemote.loadProductVariationsCallCount == 2) // 1 batch of 2 requests
    }

    @Test func startFullSync_handles_paginated_variations_correctly() async throws {
        // Given - Multiple pages of variations
        let page1Variations = [POSProductVariation.fake(), POSProductVariation.fake()]
        let page2Variations = [POSProductVariation.fake()]
        let page3Variations = [POSProductVariation.fake()]

        mockSyncRemote.setVariationResults([
            PagedItems(items: page1Variations, hasMorePages: true, totalItems: 2),
            PagedItems(items: page2Variations, hasMorePages: true, totalItems: 2),
            PagedItems(items: page3Variations, hasMorePages: false, totalItems: 2)
        ])

        // When
        let result = try await sut.startFullSync(for: sampleSiteID)

        // Then
        #expect(result.variations.count == 4)
        #expect(mockSyncRemote.loadProductsCallCount == 2) // 1 batch of 2 requests
        #expect(mockSyncRemote.loadProductVariationsCallCount == 4) // 2 batches of 2 requests
    }

    @Test func startFullSync_stops_pagination_when_no_new_items_returned_and_hasMorePages_is_inaccurate() async throws {
        // Given
        let page1Products = [POSProduct.fake()]
        let emptyPage: [POSProduct] = []

        mockSyncRemote.setProductResults([
            PagedItems(items: page1Products, hasMorePages: true, totalItems: 1),
            PagedItems(items: emptyPage, hasMorePages: true, totalItems: 1)
        ])
        mockSyncRemote.setVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        let result = try await sut.startFullSync(for: sampleSiteID)

        // Then - Should stop after empty page
        #expect(result.products.count == 1)
        #expect(mockSyncRemote.loadProductsCallCount == 4) // The results from the second batch are empty
    }

    @Test func startFullSync_handles_batch_processing_correctly() async throws {
        // Given - Service with batch size 2
        let products = (1...5).map { _ in POSProduct.fake() }

        mockSyncRemote.setProductResults([
            PagedItems(items: [products[0]], hasMorePages: true, totalItems: 5),  // Page 1
            PagedItems(items: [products[1]], hasMorePages: true, totalItems: 5),  // Page 2 (batch 1)
            PagedItems(items: [products[2]], hasMorePages: true, totalItems: 5),  // Page 3
            PagedItems(items: [products[3]], hasMorePages: true, totalItems: 5),  // Page 4 (batch 2)
            PagedItems(items: [products[4]], hasMorePages: false, totalItems: 5)  // Page 5 (batch 3)
        ])
        mockSyncRemote.setVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        let result = try await sut.startFullSync(for: sampleSiteID)

        // Then
        #expect(result.products.count == 5)
        #expect(mockSyncRemote.loadProductsCallCount == 6)
    }

    @Test func startFullSync_propagates_network_errors() async throws {
        // Given
        let expectedError = NSError(domain: "network", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        mockSyncRemote.setProductResult(pageNumber: 1, result: .failure(expectedError))

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.startFullSync(for: sampleSiteID)
        }
    }

    // MARK: - Initialization Tests

    @Test func init_with_valid_credentials_creates_service() throws {
        // Given
        let credentials = Credentials.wpcom(username: "test", authToken: "token", siteAddress: "site.com")
        let grdbManager = try GRDBManager()

        // When
        let service = POSCatalogFullSyncService(credentials: credentials, grdbManager: grdbManager)

        // Then
        #expect(service != nil)
    }

    @Test func init_with_nil_credentials_returns_nil() throws {
        // Given
        let grdbManager = try GRDBManager()

        // When
        let service = POSCatalogFullSyncService(credentials: nil, grdbManager: grdbManager)

        // Then
        #expect(service == nil)
    }

    @Test func init_with_custom_batch_size_uses_specified_size() async throws {
        // Given
        let customBatchSize = 5

        // When
        let service = POSCatalogFullSyncService(syncRemote: mockSyncRemote,
                                                batchSize: customBatchSize,
                                                persistenceService: mockPersistenceService)
        _ = try await service.startFullSync(for: sampleSiteID)

        // Then
        #expect(mockSyncRemote.loadProductsCallCount == 5)
        #expect(mockSyncRemote.loadProductVariationsCallCount == 5)
    }
}

// MARK: - Mock POSCatalogPersistenceService

private final class MockPOSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private(set) var replaceAllCatalogDataCallCount = 0
    private(set) var lastPersistedCatalog: POSCatalog?
    private(set) var lastPersistedSiteID: Int64?

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        replaceAllCatalogDataCallCount += 1
        lastPersistedSiteID = siteID
        lastPersistedCatalog = catalog
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {}
}
