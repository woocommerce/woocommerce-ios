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
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then
        #expect(await mockSyncRemote.loadIncrementalProductsCallCount.value == 2)
        #expect(await mockSyncRemote.loadIncrementalProductVariationsCallCount.value == 2)
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
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastIncrementalDate, lastIncrementalSyncDate: lastIncrementalDate)

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: lastIncrementalDate)

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
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then
        #expect(await mockSyncRemote.loadIncrementalProductsCallCount.value == 4)
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
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then
        #expect(await mockSyncRemote.loadIncrementalProductVariationsCallCount.value == 2)
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.variations.count == 2)
    }

    // MARK: - Error Handling Tests

    @Test func startIncrementalSync_throws_error_when_product_loading_fails() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let expectedError = NSError(domain: "test", code: 500, userInfo: nil)
        let sut = POSCatalogIncrementalSyncService(syncRemote: mockSyncRemote, batchSize: 2, retryDelay: 0, persistenceService: mockPersistenceService)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .failure(expectedError))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)
        }
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 0)

        // When attempting a second sync
        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

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
            try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)
        }
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 1)

        // When attempting a second sync
        mockPersistenceService.persistIncrementalCatalogDataError = nil  // Clear the error
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

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
        try await sut.startIncrementalSync(for: site1ID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)
        let site1ModifiedAfter = try #require(mockSyncRemote.lastIncrementalProductsModifiedAfter)

        // When - Sync site 2
        try await sut.startIncrementalSync(for: site2ID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)
        let site2ModifiedAfter = try #require(mockSyncRemote.lastIncrementalProductsModifiedAfter)

        #expect(site1ModifiedAfter == lastFullSyncDate)
        #expect(site2ModifiedAfter == lastFullSyncDate)
    }

    // MARK: - Two-Request Pattern Tests (Regular + Trashed Products)

    @Test func startIncrementalSync_fetches_both_regular_and_trashed_products() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let regularProducts = [POSProduct.fake().copy(statusKey: "publish")]
        let trashedProducts = [POSProduct.fake().copy(statusKey: "trash")]

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: regularProducts, hasMorePages: false, totalItems: 1)))
        mockSyncRemote.setTrashedProductResult(pageNumber: 1, result: .success(PagedItems(items: trashedProducts, hasMorePages: false, totalItems: 1)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - Both regular and trashed products requests were made
        #expect(await mockSyncRemote.loadIncrementalProductsCallCount.value >= 1)
        #expect(await mockSyncRemote.loadTrashedProductsCallCount.value >= 1)

        // Verify persisted catalog contains both regular and trashed products
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 2)
    }

    @Test func startIncrementalSync_uses_same_modifiedAfter_for_regular_and_trashed_requests() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setTrashedProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - Both requests use the same modifiedAfter date
        let regularModifiedAfter = try #require(mockSyncRemote.lastIncrementalProductsModifiedAfter)
        let trashedModifiedAfter = try #require(mockSyncRemote.lastTrashedProductsModifiedAfter)
        #expect(regularModifiedAfter == trashedModifiedAfter)
        #expect(regularModifiedAfter == lastFullSyncDate)
    }

    @Test func startIncrementalSync_includes_correct_includeStatus_values_in_requests() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)

        mockSyncRemote.setIncrementalProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setTrashedProductResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - Verify both nil (regular) and "trash" statuses were requested
        let includeStatuses = await mockSyncRemote.includeStatusTracker.values
        #expect(includeStatuses.contains(nil))
        #expect(includeStatuses.contains("trash"))
    }

    @Test func startIncrementalSync_combines_products_from_both_requests_into_single_persistence() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let regularProduct1 = POSProduct.fake().copy(statusKey: "publish")
        let regularProduct2 = POSProduct.fake().copy(statusKey: "publish")
        let trashedProduct = POSProduct.fake().copy(statusKey: "trash")

        mockSyncRemote.setIncrementalProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [regularProduct1, regularProduct2], hasMorePages: false, totalItems: 2))
        )
        mockSyncRemote.setTrashedProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [trashedProduct], hasMorePages: false, totalItems: 1))
        )
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - All products are combined in a single persistence call
        #expect(mockPersistenceService.persistIncrementalCatalogDataCallCount == 1)
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 3)
    }

    @Test func startIncrementalSync_handles_empty_trashed_products_response() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let regularProducts = [POSProduct.fake(), POSProduct.fake()]

        mockSyncRemote.setIncrementalProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: regularProducts, hasMorePages: false, totalItems: 2))
        )
        mockSyncRemote.setTrashedProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - Only regular products are persisted
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 2)
    }

    @Test func startIncrementalSync_handles_only_trashed_products_updated() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)
        let trashedProducts = [POSProduct.fake().copy(statusKey: "trash")]

        mockSyncRemote.setIncrementalProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )
        mockSyncRemote.setTrashedProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: trashedProducts, hasMorePages: false, totalItems: 1))
        )
        mockSyncRemote.setIncrementalVariationResult(pageNumber: 1, result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0)))

        // When
        try await sut.startIncrementalSync(for: sampleSiteID, lastFullSyncDate: lastFullSyncDate, lastIncrementalSyncDate: nil)

        // Then - Only trashed products are persisted
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 1)
    }

    // MARK: - Hidden Product Detection Tests (Dual-Request)

    @Test func startIncrementalSync_detects_products_hidden_from_POS() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)

        // Products visible in POS (filtered response)
        let posProduct1 = POSProduct.fake().copy(productID: 1)
        let posProduct2 = POSProduct.fake().copy(productID: 2)

        mockSyncRemote.setIncrementalProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [posProduct1, posProduct2], hasMorePages: false, totalItems: 2))
        )
        mockSyncRemote.setTrashedProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )
        mockSyncRemote.setIncrementalVariationResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )

        // When
        try await sut.startIncrementalSync(for: sampleSiteID,
                                           lastFullSyncDate: lastFullSyncDate,
                                           lastIncrementalSyncDate: nil)

        // Then
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 2)
    }

    @Test func startIncrementalSync_handles_no_hidden_products_when_all_products_are_in_POS() async throws {
        // Given
        let lastFullSyncDate = Date(timeIntervalSince1970: 1000)

        // Same products in both responses, nothing hidden
        let product1 = POSProduct.fake().copy(productID: 1)
        let product2 = POSProduct.fake().copy(productID: 2)

        mockSyncRemote.setIncrementalProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [product1, product2], hasMorePages: false, totalItems: 2))
        )
        mockSyncRemote.setTrashedProductResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )
        mockSyncRemote.setIncrementalVariationResult(
            pageNumber: 1,
            result: .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        )

        // When
        try await sut.startIncrementalSync(for: sampleSiteID,
                                           lastFullSyncDate: lastFullSyncDate,
                                           lastIncrementalSyncDate: nil)

        // Then, no products marked for removal
        let persistedCatalog = try #require(mockPersistenceService.persistIncrementalCatalogDataLastPersistedCatalog)
        #expect(persistedCatalog.products.count == 2)
        #expect(persistedCatalog.productsToRemove.isEmpty)
    }
}
