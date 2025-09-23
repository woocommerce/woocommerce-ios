import Foundation
import Testing
import GRDB
@testable import Yosemite
@testable import Storage

struct POSCatalogSettingsServiceTests {
    private let grdbManager: GRDBManager
    private let sut: POSCatalogSettingsService
    private let sampleSiteID: Int64 = 134

    init() throws {
        self.grdbManager = try GRDBManager()
        self.sut = POSCatalogSettingsService(grdbManager: grdbManager)
    }

    // MARK: - `loadCatalogInfo` Tests

    @Test(arguments: [6, 8], [7, 0])
    func loadCatalogInfo_returns_correct_counts_for_products_and_variations(productCount: Int, variationCount: Int) async throws {
        // Given
        try insertSite(siteID: sampleSiteID)
        try insertTestProducts(siteID: sampleSiteID, productCount: productCount, variationCount: variationCount)

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.productCount == productCount)
        #expect(catalogInfo.variationCount == variationCount)
    }

    @Test func loadCatalogInfo_returns_zero_counts_when_no_data_exists() async throws {
        // Given - no data in database for the site

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.productCount == 0)
        #expect(catalogInfo.variationCount == 0)
    }

    @Test func loadCatalogInfo_only_counts_items_for_specified_site() async throws {
        // Given
        let siteA: Int64 = 100
        let siteB: Int64 = 200
        try insertSite(siteID: siteA)
        try insertTestProducts(siteID: siteA, productCount: 3, variationCount: 4)
        try insertSite(siteID: siteB)
        try insertTestProducts(siteID: siteB, productCount: 2, variationCount: 1)

        // When
        let catalogInfoA = try await sut.loadCatalogInfo(for: siteA)
        let catalogInfoB = try await sut.loadCatalogInfo(for: siteB)

        // Then
        #expect(catalogInfoA.productCount == 3)
        #expect(catalogInfoA.variationCount == 4)
        #expect(catalogInfoB.productCount == 2)
        #expect(catalogInfoB.variationCount == 1)
    }

    @Test func loadCatalogInfo_returns_sync_dates_when_site_has_sync_history() async throws {
        // Given
        let fullSyncDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let incrementalSyncDate = Date(timeIntervalSinceNow: -1800) // 30 minutes ago
        try insertSite(siteID: sampleSiteID,
                       lastFullSyncDate: fullSyncDate,
                       lastIncrementalSyncDate: incrementalSyncDate)

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.lastFullSyncDate?.timeIntervalSince(fullSyncDate) ?? 0 < 1.0)
        #expect(catalogInfo.lastIncrementalSyncDate?.timeIntervalSince(incrementalSyncDate) ?? 0 < 1.0)
    }

    @Test func loadCatalogInfo_returns_nil_dates_when_site_has_no_sync_history() async throws {
        // Given
        try insertSite(siteID: sampleSiteID,
                       lastFullSyncDate: nil,
                       lastIncrementalSyncDate: nil)

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.lastFullSyncDate == nil)
        #expect(catalogInfo.lastIncrementalSyncDate == nil)
    }

    @Test func loadCatalogInfo_returns_nil_dates_when_site_does_not_exist() async throws {
        // Given - site does not exist in database

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.lastFullSyncDate == nil)
        #expect(catalogInfo.lastIncrementalSyncDate == nil)
    }

    @Test func loadCatalogInfo_returns_partial_sync_dates() async throws {
        // Given - only full sync date is set
        let fullSyncDate = Date(timeIntervalSinceNow: -7200) // 2 hours ago

        try insertSite(siteID: sampleSiteID,
                       lastFullSyncDate: fullSyncDate,
                       lastIncrementalSyncDate: nil)

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.lastFullSyncDate?.timeIntervalSince(fullSyncDate) ?? 0 < 1.0)
        #expect(catalogInfo.lastIncrementalSyncDate == nil)
    }

    @Test func loadCatalogInfo_handles_different_sites_independently() async throws {
        // Given
        let siteA: Int64 = 100
        let siteB: Int64 = 200
        let dateA = Date(timeIntervalSinceNow: -3600)
        let dateB = Date(timeIntervalSinceNow: -7200)

        try insertSite(siteID: siteA,
                       lastFullSyncDate: dateA,
                       lastIncrementalSyncDate: nil)
        try insertSite(siteID: siteB,
                       lastFullSyncDate: nil,
                       lastIncrementalSyncDate: dateB)

        // When
        let catalogInfoA = try await sut.loadCatalogInfo(for: siteA)
        let catalogInfoB = try await sut.loadCatalogInfo(for: siteB)

        // Then
        #expect(catalogInfoA.lastFullSyncDate?.timeIntervalSince(dateA) ?? 0 < 1.0)
        #expect(catalogInfoA.lastIncrementalSyncDate == nil)
        #expect(catalogInfoB.lastFullSyncDate == nil)
        #expect(catalogInfoB.lastIncrementalSyncDate?.timeIntervalSince(dateB) ?? 0 < 1.0)
    }

    @Test func loadCatalogInfo_propagates_database_errors() async throws {
        // Given - close the database to simulate an error
        try grdbManager.databaseConnection.close()

        // When/Then
        await #expect(throws: DatabaseError.self) {
            _ = try await sut.loadCatalogInfo(for: sampleSiteID)
        }
    }

    // MARK: - Concurrent Operations Tests

    @Test func concurrent_loadCatalogInfo_calls_work_correctly() async throws {
        // Given
        let siteA: Int64 = 100
        let siteB: Int64 = 200
        let dateA = Date(timeIntervalSinceNow: -3600)
        let dateB = Date(timeIntervalSinceNow: -7200)

        try insertSite(siteID: siteA, lastFullSyncDate: dateA, lastIncrementalSyncDate: nil)
        try insertTestProducts(siteID: siteA, productCount: 10, variationCount: 15)
        try insertSite(siteID: siteB, lastFullSyncDate: nil, lastIncrementalSyncDate: dateB)
        try insertTestProducts(siteID: siteB, productCount: 6, variationCount: 8)

        // When
        async let catalogInfoA = sut.loadCatalogInfo(for: siteA)
        async let catalogInfoB = sut.loadCatalogInfo(for: siteB)

        let (resultA, resultB) = try await (catalogInfoA, catalogInfoB)

        // Then
        #expect(resultA.productCount == 10)
        #expect(resultA.variationCount == 15)
        #expect(resultA.lastFullSyncDate?.timeIntervalSince(dateA) ?? 0 < 1.0)
        #expect(resultA.lastIncrementalSyncDate == nil)
        #expect(resultB.productCount == 6)
        #expect(resultB.variationCount == 8)
        #expect(resultB.lastFullSyncDate == nil)
        #expect(resultB.lastIncrementalSyncDate?.timeIntervalSince(dateB) ?? 0 < 1.0)
    }

    @Test func loadCatalogInfo_returns_complete_catalog_information() async throws {
        // Given
        let syncDate = Date(timeIntervalSinceNow: -1800)
        try insertSite(siteID: sampleSiteID, lastFullSyncDate: syncDate, lastIncrementalSyncDate: syncDate)
        try insertTestProducts(siteID: sampleSiteID, productCount: 20, variationCount: 30)

        // When
        let catalogInfo = try await sut.loadCatalogInfo(for: sampleSiteID)

        // Then
        #expect(catalogInfo.productCount == 20)
        #expect(catalogInfo.variationCount == 30)
        #expect(catalogInfo.lastFullSyncDate?.timeIntervalSince(syncDate) ?? 0 < 1.0)
        #expect(catalogInfo.lastIncrementalSyncDate?.timeIntervalSince(syncDate) ?? 0 < 1.0)
    }
}

// MARK: - Helper Methods

private extension POSCatalogSettingsServiceTests {
    func insertTestProducts(siteID: Int64, productCount: Int, variationCount: Int) throws {
        try grdbManager.databaseConnection.write { db in
            if productCount > 0 {
                for i in 1...productCount {
                    let product = PersistedProduct(from: POSProduct.fake().copy(
                        siteID: siteID,
                        productID: Int64(i),
                        name: "Product \(i)"
                    ))
                    try product.insert(db)
                }
            }

            if variationCount > 0, productCount > 0 {
                for i in 1...variationCount {
                    let variation = PersistedProductVariation(from: POSProductVariation.fake().copy(
                        siteID: siteID,
                        productID: Int64(1),
                        productVariationID: Int64(i)
                    ))
                    try variation.insert(db)
                }
            }
        }
    }

    func insertSite(siteID: Int64, lastFullSyncDate: Date? = nil, lastIncrementalSyncDate: Date? = nil) throws {
        try grdbManager.databaseConnection.write { db in
            let site = PersistedSite(
                id: siteID,
                lastCatalogIncrementalSyncDate: lastIncrementalSyncDate,
                lastCatalogFullSyncDate: lastFullSyncDate
            )
            try site.insert(db)
        }
    }
}
