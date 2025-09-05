import Foundation
import Testing
@testable import Yosemite
@testable import Storage

struct POSCatalogSyncCoordinatorTests {
    private let mockSyncService: MockPOSCatalogFullSyncService
    private let mockSettingsStore: MockSiteSpecificAppSettingsStoreMethods
    private let grdbManager: GRDBManager
    private let sut: POSCatalogSyncCoordinator
    private let sampleSiteID: Int64 = 134

    init() throws {
        self.mockSyncService = MockPOSCatalogFullSyncService()
        self.mockSettingsStore = MockSiteSpecificAppSettingsStoreMethods()
        self.grdbManager = try GRDBManager()
        self.sut = POSCatalogSyncCoordinator(
            syncService: mockSyncService,
            settingsStore: mockSettingsStore,
            grdbManager: grdbManager
        )
    }

    // MARK: - Full Sync Tests

    @Test func performFullSync_delegates_to_sync_service() async throws {
        // Given
        let expectedCatalog = POSCatalog(
            products: [POSProduct.fake()],
            variations: [POSProductVariation.fake()]
        )
        mockSyncService.startFullSyncResult = expectedCatalog

        // When
        let result = try await sut.performFullSync(for: sampleSiteID)

        // Then
        #expect(result.products.count == expectedCatalog.products.count)
        #expect(result.variations.count == expectedCatalog.variations.count)
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockSyncService.lastSyncSiteID == sampleSiteID)
    }

    @Test func performFullSync_stores_sync_timestamp() async throws {
        // Given
        let beforeSync = Date()
        let expectedCatalog = POSCatalog(products: [], variations: [])
        mockSyncService.startFullSyncResult = expectedCatalog

        // When
        _ = try await sut.performFullSync(for: sampleSiteID)
        let afterSync = Date()

        // Then
        #expect(mockSettingsStore.setPOSLastFullSyncDateCallCount == 1)
        #expect(mockSettingsStore.lastSetSiteID == sampleSiteID)

        let storedDate = mockSettingsStore.lastSetDate
        #expect(storedDate != nil)
        #expect(storedDate! >= beforeSync)
        #expect(storedDate! <= afterSync)
    }

    @Test func performFullSync_propagates_errors() async throws {
        // Given
        let expectedError = NSError(domain: "sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sync failed"])
        mockSyncService.startFullSyncError = expectedError

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.performFullSync(for: sampleSiteID)
        }

        // Should not store timestamp on failure
        #expect(mockSettingsStore.setPOSLastFullSyncDateCallCount == 0)
    }

    // MARK: - Should Sync Decision Tests

    @Test func shouldPerformFullSync_site_not_in_database_with_no_sync_history() {
        // Given - site doesn't exist in database AND has no sync history
        mockSettingsStore.storedDates = [:]
        // Note: NOT creating site in database

        // When
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then - should sync because site doesn't exist in database
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_true_when_no_previous_sync() throws {
        // Given - no previous sync date stored, but site exists in database
        // This is much less likely to happen, but could help at a migration point
        mockSettingsStore.storedDates = [:]
        try createSiteInDatabase(siteID: sampleSiteID)

        // When
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 3600)

        // Then
        #expect(shouldSync == true)
        #expect(mockSettingsStore.getPOSLastFullSyncDateCallCount == 1)
    }

    @Test func shouldPerformFullSync_returns_true_when_sync_is_stale() throws {
        // Given - previous sync was 2 hours ago, and site exists in database
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        mockSettingsStore.storedDates[sampleSiteID] = twoHoursAgo
        try createSiteInDatabase(siteID: sampleSiteID)

        // When - max age is 1 hour
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_false_when_sync_is_fresh() throws {
        // Given - previous sync was 30 minutes ago, and site exists in database
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        mockSettingsStore.storedDates[sampleSiteID] = thirtyMinutesAgo
        try createSiteInDatabase(siteID: sampleSiteID)

        // When - max age is 1 hour
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == false)
    }

    @Test func shouldPerformFullSync_handles_different_sites_independently() throws {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)

        mockSettingsStore.storedDates[siteA] = oneHourAgo // Has previous sync
        // siteB has no previous sync

        // Create both sites in database to test timing logic
        try createSiteInDatabase(siteID: siteA)
        try createSiteInDatabase(siteID: siteB)

        // When
        let shouldSyncA = sut.shouldPerformFullSync(for: siteA, maxAge: 2 * 60 * 60) // 2 hours
        let shouldSyncB = sut.shouldPerformFullSync(for: siteB, maxAge: 2 * 60 * 60) // 2 hours

        // Then
        #expect(shouldSyncA == false) // Recent sync exists
        #expect(shouldSyncB == true)  // No previous sync
    }

    @Test func shouldPerformFullSync_with_zero_maxAge_always_returns_true() throws {
        // Given - previous sync was just now, and site exists in database
        let justNow = Date()
        mockSettingsStore.storedDates[sampleSiteID] = justNow
        try createSiteInDatabase(siteID: sampleSiteID)

        // When - max age is 0 (always sync)
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 0)

        // Then
        #expect(shouldSync == true)
    }

    // MARK: - Database Check Tests

    @Test func shouldPerformFullSync_returns_true_when_site_not_in_database() {
        // Given - site does not exist in database, but has recent sync date
        let recentSyncDate = Date().addingTimeInterval(-30 * 60) // 30 minutes ago
        mockSettingsStore.storedDates[sampleSiteID] = recentSyncDate
        // Note: not creating site in database so it won't exist

        // When - max age is 1 hour (normally wouldn't sync)
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then - should sync because site doesn't exist in database
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_respects_time_when_site_exists_in_database() throws {
        // Given - site exists in database with recent sync date
        let recentSyncDate = Date().addingTimeInterval(-30 * 60) // 30 minutes ago
        mockSettingsStore.storedDates[sampleSiteID] = recentSyncDate
        try createSiteInDatabase(siteID: sampleSiteID)

        // When - max age is 1 hour
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then - should not sync because site exists and time hasn't passed
        #expect(shouldSync == false)
    }

    // MARK: - Helper Methods

    private func createSiteInDatabase(siteID: Int64) throws {
        try grdbManager.databaseConnection.write { db in
            let site = PersistedSite(id: siteID)
            try site.insert(db)
        }
    }
}

// MARK: - Mock Services

final class MockPOSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    var startFullSyncResult: POSCatalog = POSCatalog(products: [], variations: [])
    var startFullSyncError: Error?

    private(set) var startFullSyncCallCount = 0
    private(set) var lastSyncSiteID: Int64?

    func startFullSync(for siteID: Int64) async throws -> POSCatalog {
        startFullSyncCallCount += 1
        lastSyncSiteID = siteID

        if let error = startFullSyncError {
            throw error
        }

        return startFullSyncResult
    }
}
