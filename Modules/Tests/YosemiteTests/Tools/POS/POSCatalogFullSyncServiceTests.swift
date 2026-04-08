import Foundation
import Testing
import Combine
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
        self.sut = POSCatalogFullSyncService(syncRemote: mockSyncRemote, batchSize: 2, persistenceService: mockPersistenceService, usesCatalogAPI: false)
    }

    // MARK: - Full Sync Tests

    @Test func startFullSync_loads_products_and_variations() async throws {
        // Given
        let expectedProducts = [POSProduct.fake(), POSProduct.fake()]
        let expectedVariations = [POSProductVariation.fake()]

        mockSyncRemote.setProductResult(pageNumber: 1, result: .success(PagedItems(items: expectedProducts, hasMorePages: false, totalItems: 0)))
        mockSyncRemote.setVariationResult(pageNumber: 1, result: .success(PagedItems(items: expectedVariations, hasMorePages: false, totalItems: 0)))

        // When
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(result.products.count == expectedProducts.count)
        #expect(result.variations.count == expectedVariations.count)
        #expect(await mockSyncRemote.loadProductsCallCount.value == 2) // 1 batch of 2 requests
        #expect(await mockSyncRemote.loadProductVariationsCallCount.value == 2) // 1 batch of 2 requests
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
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(result.products.count == 3)
        #expect(await mockSyncRemote.loadProductsCallCount.value == 4) // 2 batches of 2 requests
        #expect(await mockSyncRemote.loadProductVariationsCallCount.value == 2) // 1 batch of 2 requests
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
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(result.variations.count == 4)
        #expect(await mockSyncRemote.loadProductsCallCount.value == 2) // 1 batch of 2 requests
        #expect(await mockSyncRemote.loadProductVariationsCallCount.value == 4) // 2 batches of 2 requests
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
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then - Should stop after empty page
        #expect(result.products.count == 1)
        #expect(await mockSyncRemote.loadProductsCallCount.value == 4) // The results from the second batch are empty
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
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(result.products.count == 5)
        #expect(await mockSyncRemote.loadProductsCallCount.value == 6)
    }

    @Test func startFullSync_propagates_network_errors() async throws {
        // Given
        let expectedError = NSError(domain: "network", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        mockSyncRemote.setProductResult(pageNumber: 1, result: .failure(expectedError))
        let sut = POSCatalogFullSyncService(syncRemote: mockSyncRemote,
                                            batchSize: 2,
                                            retryDelay: 0,
                                            persistenceService: mockPersistenceService,
                                            usesCatalogAPI: false)

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)
        }
    }

    // MARK: - Initialization Tests

    @Test func init_with_valid_credentials_creates_service() throws {
        // Given
        let credentials = Credentials.wpcom(username: "test", authToken: "token", siteAddress: "site.com")
        let grdbManager = try GRDBManager()

        // When
        let service = POSCatalogFullSyncService(
            credentials: credentials,
            selectedSite: Just(Site.fake()).map { $0.toJetpackSite() }.eraseToAnyPublisher(),
            appPasswordSupportState: Just(false).eraseToAnyPublisher(),
            grdbManager: grdbManager,
            usesCatalogAPI: false
        )

        // Then
        #expect(service != nil)
    }

    @Test func init_with_nil_credentials_returns_nil() throws {
        // Given
        let grdbManager = try GRDBManager()

        // When
        let service = POSCatalogFullSyncService(
            credentials: nil,
            selectedSite: Just(Site.fake()).map { $0.toJetpackSite() }.eraseToAnyPublisher(),
            appPasswordSupportState: Just(false).eraseToAnyPublisher(),
            grdbManager: grdbManager,
            usesCatalogAPI: false
        )

        // Then
        #expect(service == nil)
    }

    @Test func init_with_custom_batch_size_uses_specified_size() async throws {
        // Given
        let customBatchSize = 5

        // When
        let service = POSCatalogFullSyncService(syncRemote: mockSyncRemote,
                                                batchSize: customBatchSize,
                                                persistenceService: mockPersistenceService,
                                                usesCatalogAPI: false)
        _ = try await service.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(await mockSyncRemote.loadProductsCallCount.value == 5)
        #expect(await mockSyncRemote.loadProductVariationsCallCount.value == 5)
    }

    // MARK: - Catalog API Tests

    @Test func startFullSync_with_catalog_API_downloads_and_persists_catalog() async throws {
        // Given
        let expectedProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1)
        let expectedVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 1)

        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [expectedProduct],
                                                                       variations: [POSTypedVariation(variation: expectedVariation, typeKey: "variation")]))

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(result.products.count == 1)
        #expect(result.variations.count == 1)
        #expect(mockPersistenceService.replaceAllCatalogDataCallCount == 1)
        #expect(mockPersistenceService.replaceAllCatalogDataLastPersistedCatalog?.products.count == 1)
        #expect(mockPersistenceService.replaceAllCatalogDataLastPersistedCatalog?.variations.count == 1)
    }

    @Test func startFullSync_with_catalog_API_propagates_catalog_request_error() async throws {
        // Given
        let expectedError = NSError(domain: "catalog", code: 500, userInfo: [NSLocalizedDescriptionKey: "Catalog request failed"])
        mockSyncRemote.catalogRequestResult = .failure(expectedError)

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)
        }
    }

    @Test func startFullSync_with_catalog_API_propagates_catalog_download_error() async throws {
        // Given
        let expectedError = NSError(domain: "catalog", code: 404, userInfo: [NSLocalizedDescriptionKey: "Catalog download failed"])
        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .failure(expectedError)

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)
        }
    }

    @Test func startFullSync_with_catalog_API_propagates_persistence_error() async throws {
        // Given
        let expectedError = NSError(domain: "persistence", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Persistence failed"])
        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [], variations: []))
        mockPersistenceService.replaceAllCatalogDataError = expectedError

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)
        }
    }

    @Test(arguments: [true, false])
    func startFullSync_with_catalog_API_passes_regenerateCatalog_to_remote(regenerateCatalog: Bool) async throws {
        // Given
        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [], variations: []))

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When
        _ = try await sut.startFullSync(for: sampleSiteID, regenerateCatalog: regenerateCatalog, allowCellular: true, isBackgroundSync: false)

        // Then
        #expect(mockSyncRemote.lastCatalogRequestForceGeneration == regenerateCatalog)
    }

    @Test(arguments: [true, false])
    func startFullSync_with_catalog_API_passes_allowCellular_to_downloadCatalog(allowCellular: Bool) async throws {
        // Given
        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [], variations: []))

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When
        _ = try await sut.startFullSync(for: sampleSiteID, regenerateCatalog: false, allowCellular: allowCellular, isBackgroundSync: false)

        // Then
        #expect(mockSyncRemote.lastCatalogDownloadAllowCellular == allowCellular)
    }

    // MARK: - Exponential Backoff Polling Tests

    @Test func startFullSync_polls_with_exponential_backoff_until_completed() async throws {
        // Given - First request returns scheduled (no URL), then after polling returns completed with URL
        mockSyncRemote.catalogRequestSequence = [
            .success(.init(status: .scheduled, downloadURL: nil)),  // Initial request
            .success(.init(status: .processing, downloadURL: nil)), // Poll 1
            .success(.init(status: .processing, downloadURL: nil)), // Poll 2
            .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json")) // Poll 3 - success
        ]
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [], variations: []))

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When
        let result = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then - Should have made 4 catalog request calls (1 initial + 3 polls)
        #expect(mockSyncRemote.catalogRequestCallCount == 4)
        #expect(result.products.isEmpty)
        #expect(result.variations.isEmpty)
    }

    @Test func startFullSync_throws_generationFailed_when_catalog_fails() async throws {
        // Given - Returns failed status
        mockSyncRemote.catalogRequestSequence = [
            .success(.init(status: .scheduled, downloadURL: nil)),  // Initial request
            .success(.init(status: .processing, downloadURL: nil)), // Poll 1
            .success(.init(status: .failed, downloadURL: nil))      // Poll 2 - failed
        ]

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When/Then - Should throw generationFailed
        await #expect(throws: POSCatalogSyncError.generationFailed) {
            _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)
        }

        // Verify it stopped after receiving failed status
        #expect(mockSyncRemote.catalogRequestCallCount == 3)
    }

    @Test func startFullSync_skips_polling_when_initial_request_has_download_url() async throws {
        // Given - First request already has download URL (catalog already generated)
        mockSyncRemote.catalogRequestResult = .success(.init(status: .completed, downloadURL: "https://example.com/catalog.json"))
        mockSyncRemote.catalogDownloadResult = .success(.init(products: [], variations: []))

        let sut = POSCatalogFullSyncService(
            syncRemote: mockSyncRemote,
            batchSize: 2,
            persistenceService: mockPersistenceService,
            usesCatalogAPI: true
        )

        // When
        _ = try await sut.startFullSync(for: sampleSiteID, allowCellular: true, isBackgroundSync: false)

        // Then - Should only make 1 catalog request call (no polling needed)
        #expect(mockSyncRemote.catalogRequestCallCount == 1)
    }

    @Test func pollingConfig_has_correct_values() {
        // Verify the polling configuration constants match the PRD requirements
        #expect(POSCatalogFullSyncService.PollingConfig.initialDelay == 3.0)
        #expect(POSCatalogFullSyncService.PollingConfig.multiplier == 1.3)
        #expect(POSCatalogFullSyncService.PollingConfig.maxInterval == 20.0)
        #expect(POSCatalogFullSyncService.PollingConfig.foregroundMaxAttempts == 20)
        #expect(POSCatalogFullSyncService.PollingConfig.backgroundMaxAttempts == 4)
    }
}
