import Foundation
import Testing
@testable import Yosemite
@testable import Storage

struct POSCatalogSyncCoordinatorTests {
    private let mockSyncService: MockPOSCatalogFullSyncService
    private let mockPersistenceService: MockPOSCatalogPersistenceService
    private let grdbManager: GRDBManager
    private let sut: POSCatalogSyncCoordinator
    private let sampleSiteID: Int64 = 134

    init() throws {
        self.mockSyncService = MockPOSCatalogFullSyncService()
        self.mockPersistenceService = MockPOSCatalogPersistenceService()
        self.grdbManager = try GRDBManager()
        self.sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            persistenceService: mockPersistenceService,
            grdbManager: grdbManager
        )
    }

    // MARK: - Full Sync Tests

    @Test func performFullSync_delegates_to_sync_service() async throws {
        // Given
        let expectedCatalog = POSCatalog(
            products: [POSProduct.fake()],
            variations: [POSProductVariation.fake()],
            syncDate: .now
        )
        mockSyncService.startFullSyncResult = .success(expectedCatalog)

        // When
        try await sut.performFullSync(for: sampleSiteID)

        // Then
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockSyncService.lastSyncSiteID == sampleSiteID)
    }

    @Test func performFullSync_propagates_errors() async throws {
        // Given
        let expectedError = NSError(domain: "sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sync failed"])
        mockSyncService.startFullSyncResult = .failure(expectedError)

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.performFullSync(for: sampleSiteID)
        }
    }

    // MARK: - Should Sync Decision Tests

    @Test func shouldPerformFullSync_returns_true_when_site_is_not_in_database_with_no_sync_history() async {
        // Given - site does not exist in database
        // Note: not creating site in database so it won't exist

        // When
        let shouldSync = await sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then - should sync because site doesn't exist in database
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_true_when_site_has_no_previous_sync() async throws {
        // Given - site exists in database but has no previous sync date
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When
        let shouldSync = await sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 3600)

        // Then
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_true_when_sync_is_stale() async throws {
        // Given - previous sync was 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twoHoursAgo)

        // When - max age is 1 hour
        let shouldSync = await sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_false_when_sync_is_fresh() async throws {
        // Given - previous sync was 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: thirtyMinutesAgo)

        // When - max age is 1 hour
        let shouldSync = await sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == false)
    }

    @Test func shouldPerformFullSync_handles_different_sites_independently() async throws {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)

        // Create sites with different sync states
        try createSiteInDatabase(siteID: siteA, lastFullSyncDate: oneHourAgo)
        try createSiteInDatabase(siteID: siteB, lastFullSyncDate: nil)

        // When
        let shouldSyncA = await sut.shouldPerformFullSync(for: siteA, maxAge: 2 * 60 * 60) // 2 hours
        let shouldSyncB = await sut.shouldPerformFullSync(for: siteB, maxAge: 2 * 60 * 60) // 2 hours

        // Then
        #expect(shouldSyncA == false) // Recent sync exists
        #expect(shouldSyncB == true)  // No previous sync
    }

    @Test func shouldPerformFullSync_with_zero_maxAge_always_returns_true() async throws {
        // Given - previous sync was just now
        let justNow = Date()
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: justNow)

        // When - max age is 0 (always sync)
        let shouldSync = await sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 0)

        // Then
        #expect(shouldSync == true)
    }

    // MARK: - Sync Tracking Tests

    @Test func performFullSync_throws_error_when_sync_already_in_progress() async throws {
        // Given - block the sync service so first sync will wait
        let expectedCatalog = POSCatalog(products: [], variations: [], syncDate: .now)
        mockSyncService.startFullSyncResult = .success(expectedCatalog)
        mockSyncService.blockNextSync()

        // Start first sync in a task (it will block waiting for continuation)
        let firstSyncTask = Task {
            try await sut.performFullSync(for: sampleSiteID)
        }

        // Give first sync a moment to start and get blocked
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // When - try to start second sync while first is blocked
        do {
            _ = try await sut.performFullSync(for: sampleSiteID)
            #expect(Bool(false), "Should have thrown syncAlreadyInProgress error")
        } catch let error as POSCatalogSyncError {
            // Then
            #expect(error == POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID))
        }

        // Cleanup - resume the first sync and wait for it to complete
        mockSyncService.resumeBlockedSync()
        _ = try await firstSyncTask.value
    }

    @Test func performFullSync_allows_concurrent_syncs_for_different_sites() async throws {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let expectedCatalog = POSCatalog(products: [], variations: [], syncDate: .now)
        mockSyncService.startFullSyncResult = .success(expectedCatalog)

        // When - start syncs for different sites concurrently
        async let syncA: () = sut.performFullSync(for: siteA)
        async let syncB: () = sut.performFullSync(for: siteB)

        // Then - both should complete successfully
        try await syncA
        try await syncB
        #expect(mockSyncService.startFullSyncCallCount == 2)
    }

    @Test func sync_tracking_cleaned_up_on_error() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
        mockSyncService.startFullSyncResult = .failure(expectedError)

        // When - sync fails
        do {
            _ = try await sut.performFullSync(for: sampleSiteID)
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected error
        }

        // Then - subsequent sync should be allowed
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        try await sut.performFullSync(for: sampleSiteID)
    }

    // MARK: - Helper Methods

    private func createSiteInDatabase(siteID: Int64, lastFullSyncDate: Date? = nil) throws {
        try grdbManager.databaseConnection.write { db in
            let site = PersistedSite(id: siteID, lastCatalogFullSyncDate: lastFullSyncDate)
            try site.insert(db)
        }
    }
}

// MARK: - Mock Services

final class MockPOSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    var startFullSyncResult: Result<POSCatalog, Error> = .success(POSCatalog(products: [], variations: [], syncDate: .now))
    var syncDelay: UInt64 = 0 // nanoseconds to delay before returning

    // Controlled sync mechanism
    private var syncContinuation: CheckedContinuation<Void, Never>?
    private var shouldBlockSync = false

    private(set) var startFullSyncCallCount = 0
    private(set) var lastSyncSiteID: Int64?

    func startFullSync(for siteID: Int64) async throws -> POSCatalog {
        startFullSyncCallCount += 1
        lastSyncSiteID = siteID

        // If we should block, wait for continuation to be resumed
        if shouldBlockSync {
            await withCheckedContinuation { continuation in
                syncContinuation = continuation
            }
        }

        // Add delay if specified
        if syncDelay > 0 {
            try await Task.sleep(nanoseconds: syncDelay)
        }

        switch startFullSyncResult {
        case .success(let catalog):
            return catalog
        case .failure(let error):
            throw error
        }
    }

    func blockNextSync() {
        shouldBlockSync = true
    }

    func resumeBlockedSync() {
        syncContinuation?.resume()
        syncContinuation = nil
        shouldBlockSync = false
    }
}
