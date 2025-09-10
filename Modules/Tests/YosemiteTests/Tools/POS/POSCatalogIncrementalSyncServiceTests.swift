import Foundation
import Testing
@testable import Networking
@testable import Yosemite
@testable import Storage

struct POSCatalogIncrementalSyncServiceTests {
    private let sut: POSCatalogIncrementalSyncService
    private let mockSyncRemote: MockPOSCatalogSyncRemote
    private let mockPersistenceService: MockPOSCatalogPersistenceService
    private let sampleSiteID: Int64 = 134

    init() {
        self.mockSyncRemote = MockPOSCatalogSyncRemote()
        self.mockPersistenceService = MockPOSCatalogPersistenceService()
        self.sut = POSCatalogIncrementalSyncService(syncRemote: mockSyncRemote, batchSize: 2, persistenceService: mockPersistenceService)
    }

    // MARK: - Basic Incremental Sync Tests

    @Test func startIncrementalSync_uses_lastFullSyncDate_as_modifiedAfter_date_when_not_synced_before() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let expectedProducts = [POSProduct.fake(), POSProduct.fake()]
        let expectedVariations = [POSProductVariation.fake()]

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: expectedProducts, hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: expectedVariations, hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then
        #expect(mockSyncRemote.loadIncrementalProductsCallCount == 2)
        #expect(mockSyncRemote.loadIncrementalProductVariationsCallCount == 2)
        #expect(mockSyncRemote.lastIncrementalProductsModifiedAfter == lastFullSyncDate)
        #expect(mockSyncRemote.lastIncrementalVariationsModifiedAfter == lastFullSyncDate)
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 1)
    }

    @Test func startIncrementalSync_uses_last_incremental_sync_date_as_modifiedAfter_date_when_available() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let lastIncrementalDate = Date(timeIntervalSince1970: 2000)

        // First sync to establish incremental date.
        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastIncrementalDate)

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then
        #expect(mockSyncRemote.lastIncrementalProductsModifiedAfter != lastFullSyncDate)
        #expect(mockSyncRemote.lastIncrementalVariationsModifiedAfter != lastFullSyncDate)
    }

    // MARK: - Pagination Tests

    @Test func startIncrementalSync_handles_paginated_products_correctly() async throws {
        // Given - 3 pages of products
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let page1Products = [POSProduct.fake()]
        let page2Products = [POSProduct.fake()]
        let page3Products = [POSProduct.fake()]

        mockSyncRemote.setIncrementalProductResults([
            PagedItems(items: page1Products, hasMorePages: true, totalItems: 3),
            PagedItems(items: page2Products, hasMorePages: true, totalItems: 3),
            PagedItems(items: page3Products, hasMorePages: false, totalItems: 3)
        ])
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then
        #expect(mockSyncRemote.loadIncrementalProductsCallCount == 4)
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 3)
    }

    @Test func startIncrementalSync_handles_paginated_variations_correctly() async throws {
        // Given - 2 pages of variations
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let page1Variations = [POSProductVariation.fake()]
        let page2Variations = [POSProductVariation.fake()]

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResults([
            PagedItems(items: page1Variations, hasMorePages: true, totalItems: 2),
            PagedItems(items: page2Variations, hasMorePages: false, totalItems: 2)
        ])

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then
        #expect(mockSyncRemote.loadIncrementalProductVariationsCallCount == 2)
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.variations.count == 2)
    }

    // MARK: - Error Handling Tests

    @Test func startIncrementalSync_throws_error_when_product_loading_fails() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let expectedError = NSError(domain: "test", code: 500, userInfo: nil)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .failure(expectedError))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)
        }
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 0)

        // When attempting a second sync
        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then it uses lastFullSyncDate since no incremental date was stored due to previous failure
        #expect(mockSyncRemote.lastIncrementalProductsModifiedAfter == lastFullSyncDate)
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 1)
    }

    @Test func startIncrementalSync_throws_error_when_persistence_fails() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let expectedError = NSError(domain: "persistence", code: 500, userInfo: nil)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockPersistenceService.persistIncrementalCatalogDataError = expectedError

        // When/Then
        await #expect(throws: Error.self) {
            try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)
        }
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 1)

        // When attempting a second sync
        mockPersistenceService.persistIncrementalCatalogDataError = nil  // Clear the error
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate)

        // Then it uses lastFullSyncDate since no incremental date was stored due to previous persistence failure
        #expect(mockSyncRemote.lastIncrementalProductsModifiedAfter == lastFullSyncDate)
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 2)
    }

    // MARK: - Per-Site Behavior Tests

    @Test func startIncrementalSync_manages_sync_dates_per_site() async throws {
        // Given
        let site1ID: Int64 = 123
        let site2ID: Int64 = 456
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When - Sync site 1
        try await sut.startIncrementalSync(for: site1ID, lastFullSyncDate: lastFullSyncDate)
        let site1ModifiedAfter = try #require(mockSyncRemote.lastIncrementalProductsModifiedAfter)

        // When - Sync site 2
        try await sut.startIncrementalSync(for: site2ID, lastFullSyncDate: lastFullSyncDate)
        let site2ModifiedAfter = try #require(mockSyncRemote.lastIncrementalProductsModifiedAfter)

        #expect(site1ModifiedAfter == lastFullSyncDate)
        #expect(site2ModifiedAfter == lastFullSyncDate)
    }
}
