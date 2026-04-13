import Foundation
import Testing
@testable import Yosemite
@testable import Storage

struct POSCatalogSyncCoordinatorTests {
    private let mockSyncService: MockPOSCatalogFullSyncService
    private let mockIncrementalSyncService: MockPOSCatalogIncrementalSyncService
    private let grdbManager: GRDBManager
    private let mockSiteSettings: MockSiteSpecificAppSettingsStoreMethods
    private let mockEligibilityChecker: MockPOSLocalCatalogEligibilityService
    private let sut: POSCatalogSyncCoordinator
    private let sampleSiteID: Int64 = 134
    private let sampleMaxAge: TimeInterval = 60 * 60

    init() throws {
        self.mockSyncService = MockPOSCatalogFullSyncService()
        self.mockIncrementalSyncService = MockPOSCatalogIncrementalSyncService()
        self.grdbManager = try GRDBManager()
        self.mockSiteSettings = MockSiteSpecificAppSettingsStoreMethods()
        self.mockEligibilityChecker = MockPOSLocalCatalogEligibilityService()
        self.sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings
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

    @Test func performFullSyncIfApplicable_throws_error_when_max_age_is_negative() async throws {
        // Given
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-30 * 60))

        // When/Then
        await #expect(throws: POSCatalogSyncError.negativeMaxAge) {
            let _ = try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: -0.01)
        }

        #expect(mockSyncService.startFullSyncCallCount == 0)
    }

    @Test func performFullSyncIfApplicable_starts_sync_when_site_is_not_in_database_with_no_sync_history() async throws {
        // Given - site does not exist in database
        // Note: not creating site in database so it won't exist

        // When
        let _ = try await sut.performFullSync(for: sampleSiteID)

        // Then - should sync because site doesn't exist in database
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performFullSyncIfApplicable_starts_sync_when_site_has_no_previous_sync() async throws {
        // Given - site exists in database but has no previous sync date
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performFullSyncIfApplicable_starts_sync_when_sync_is_stale() async throws {
        // Given - previous sync was 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * sampleMaxAge)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twoHoursAgo)

        // When - max age is 1 hour
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performFullSyncIfApplicable_skips_sync_when_sync_is_fresh() async throws {
        // Given - previous sync was 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: thirtyMinutesAgo)

        // When - max age is 1 hour / Then
        await #expect(throws: POSCatalogSyncError.shouldNotSync) {
            try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }

        #expect(mockSyncService.startFullSyncCallCount == 0)
    }

    @Test func performFullSyncIfApplicable_handles_different_sites_independently() async throws {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)

        // Create sites with different sync states
        try createSiteInDatabase(siteID: siteA, lastFullSyncDate: oneHourAgo)
        try createSiteInDatabase(siteID: siteB, lastFullSyncDate: nil)

        // When / Then
        await #expect(throws: POSCatalogSyncError.shouldNotSync) {
            let _ = try await sut.performFullSyncIfApplicable(for: siteA, maxAge: 2 * sampleMaxAge)
        }
        let _ = try await sut.performFullSyncIfApplicable(for: siteB, maxAge: 2 * sampleMaxAge)

        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockSyncService.lastSyncSiteID == siteB)
    }

    @Test func performFullSyncIfApplicable_with_zero_maxAge_skips_age_check() async throws {
        // Given - previous sync was just now
        let justNow = Date()
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: justNow)

        // When - max age is 0 (always sync)
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: 0)

        // Then
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    // MARK: - Database Check Tests

    @Test func performFullSyncIfApplicable_starts_sync_when_site_not_in_database() async throws {
        // Given - site does not exist in database, but has recent sync date
        // Note: not creating site in database so it won't exist

        // When - max age is 1 hour (normally wouldn't sync)
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then - should sync because site doesn't exist in database
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performFullSyncIfApplicable_respects_time_when_site_exists_in_database() async throws {
        // Given - site exists in database with recent sync date
        let recentSyncDate = Date().addingTimeInterval(-30 * 60) // 30 minutes ago
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: recentSyncDate)

        // When - max age is 1 hour
        // Then - should not sync because site exists and time hasn't passed
        await #expect(throws: POSCatalogSyncError.shouldNotSync) {
            let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }

        #expect(mockSyncService.startFullSyncCallCount == 0)
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

        // Wait until sync is actually blocked
        await mockSyncService.waitUntilSyncBlocked()

        // When - try to start second sync while first is blocked
        await #expect(throws: POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID)) {
            _ = try await sut.performFullSync(for: sampleSiteID)
        }

        let currentState = await sut.loadLastFullSyncState(for: sampleSiteID)
        let isSyncStarted: Bool = switch currentState {
        case .syncStarted, .initialSyncStarted: true
        default: false
        }
        #expect(isSyncStarted)

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

    // MARK: - Incremental Sync Tests

    @Test func performIncrementalSyncIfApplicable_throws_error_when_max_age_is_negative() async throws {
        // Given
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-30 * 60))

        // When/Then
        await #expect(throws: POSCatalogSyncError.negativeMaxAge) {
            let _ = try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: -0.01)
        }

        #expect(mockSyncService.startFullSyncCallCount == 0)
    }

    @Test(arguments: [.zero, 60 * 60])
    func performIncrementalSyncIfApplicable_skips_sync_when_no_full_sync_performed(maxAge: TimeInterval) async throws {
        // Given - site exists but has no full sync date
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)

        // Then
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performIncrementalSyncIfApplicable_skips_sync_when_incremental_sync_is_within_max_age() async throws {
        // Given
        let maxAge: TimeInterval = 60 // 60 seconds
        let incrementalSyncDate = Date().addingTimeInterval(-30) // 30 seconds ago (within maxAge)
        let fullSyncDate = Date().addingTimeInterval(-7200)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate, lastIncrementalSyncDate: incrementalSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)

        // Then - should not sync because 30 seconds < 60 second maxAge
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test(arguments: [.zero, 2])
    func performIncrementalSyncIfApplicable_performs_sync_when_incremental_sync_is_stale(maxAge: TimeInterval) async throws {
        // Given
        let incrementalSyncDate = Date().addingTimeInterval(-(maxAge + 0.2)) // Just above max age
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate, lastIncrementalSyncDate: incrementalSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)

        // Then
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
        #expect(mockIncrementalSyncService.lastSyncSiteID == sampleSiteID)
    }

    @Test(arguments: [.zero, 60 * 60])
    func performIncrementalSyncIfApplicable_performs_sync_when_no_incremental_sync_date(maxAge: TimeInterval) async throws {
        // Given
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate, lastIncrementalSyncDate: nil)

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)

        // Then
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
        #expect(mockIncrementalSyncService.lastSyncSiteID == sampleSiteID)
    }

    @Test func performIncrementalSync_bypasses_age_check() async throws {
        // Given
        let incrementalSyncDate = Date().addingTimeInterval(-5000) // A long time since the last incremental sync
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate, lastIncrementalSyncDate: incrementalSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )

        // When
        try await sut.performIncrementalSync(for: sampleSiteID)

        // Then
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
        #expect(mockIncrementalSyncService.lastSyncSiteID == sampleSiteID)
    }

    @Test func performIncrementalSyncIfApplicable_throws_error_when_sync_already_in_progress() async throws {
        // Given
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate)
        mockIncrementalSyncService.blockNextSync()

        // Start first incremental sync (it will block)
        let firstSyncTask = Task {
            try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }

        // Wait until sync is actually blocked
        await mockIncrementalSyncService.waitUntilSyncBlocked()

        // When - try to start second incremental sync while first is blocked
        await #expect(throws: POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID)) {
            try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }

        // Cleanup
        mockIncrementalSyncService.resumeBlockedSync()
        _ = try await firstSyncTask.value
    }

    @Test func performIncrementalSyncIfApplicable_allows_concurrent_syncs_for_different_sites() async throws {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let fullSyncDate = Date().addingTimeInterval(-3600)

        try createSiteInDatabase(siteID: siteA, lastFullSyncDate: fullSyncDate)
        try createSiteInDatabase(siteID: siteB, lastFullSyncDate: fullSyncDate)

        // When
        async let syncA: () = sut.performIncrementalSyncIfApplicable(for: siteA, maxAge: sampleMaxAge)
        async let syncB: () = sut.performIncrementalSyncIfApplicable(for: siteB, maxAge: sampleMaxAge)

        // Then
        try await syncA
        try await syncB
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 2)
    }

    @Test func performIncrementalSyncIfApplicable_propagates_errors() async throws {
        // Given
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate)

        let expectedError = NSError(domain: "incremental_sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Incremental sync failed"])
        mockIncrementalSyncService.startIncrementalSyncResult = .failure(expectedError)

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }
    }

    @Test(arguments: [.zero, 60 * 60])
    func performIncrementalSyncIfApplicable_incremental_tracking_cleaned_up_on_error(maxAge: TimeInterval) async throws {
        // Given
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate)

        let expectedError = NSError(domain: "test", code: 1, userInfo: nil)
        mockIncrementalSyncService.startIncrementalSyncResult = .failure(expectedError)

        // When - incremental sync fails
        do {
            _ = try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected error
        }

        // Then - subsequent incremental sync should be allowed
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 2)
    }

    // MARK: - Smart Sync Tests

    @Test func performSmartSync_performs_full_sync_when_last_full_sync_older_than_threshold() async throws {
        // Given - last full sync was 25 hours ago (older than 24 hour threshold)
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twentyFiveHoursAgo)

        // When
        try await sut.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - should perform full sync
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_performs_incremental_sync_when_last_full_sync_within_threshold() async throws {
        // Given - last full sync was 12 hours ago (within 24 hour threshold)
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twelveHoursAgo)

        // When
        try await sut.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - should perform incremental sync
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_performs_full_sync_when_no_previous_sync() async throws {
        // Given - no previous sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When
        try await sut.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - should perform full sync
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_respects_custom_fullSyncMaxAge() async throws {
        // Given - last full sync was 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twoHoursAgo)

        // When - using custom threshold of 1 hour for full sync and 30 minutes for incremental sync
        let oneHour: TimeInterval = 60 * 60
        let thirtyMinutes: TimeInterval = 30 * 60
        try await sut.performSmartSync(for: sampleSiteID, fullSyncMaxAge: oneHour, incrementalSyncMaxAge: thirtyMinutes, isBackgroundSync: false)

        // Then - should perform full sync because last sync is older than 1 hour
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_performs_incremental_sync_with_custom_threshold() async throws {
        // Given - last full sync was 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: thirtyMinutesAgo)

        // When - using custom threshold of 1 hour for full sync and 15 minutes for incremental sync
        let oneHour: TimeInterval = 60 * 60
        let fifteenMinutes: TimeInterval = 15 * 60
        try await sut.performSmartSync(for: sampleSiteID, fullSyncMaxAge: oneHour, incrementalSyncMaxAge: fifteenMinutes, isBackgroundSync: false)

        // Then - should perform incremental sync because last sync is within 1 hour
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_propagates_full_sync_errors() async throws {
        // Given - last full sync was 25 hours ago (should trigger full sync)
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twentyFiveHoursAgo)

        let expectedError = NSError(domain: "full_sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Full sync failed"])
        mockSyncService.startFullSyncResult = .failure(expectedError)

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.performSmartSync(for: sampleSiteID, isBackgroundSync: false)
        }
    }

    @Test func performSmartSync_propagates_incremental_sync_errors() async throws {
        // Given - last full sync was 12 hours ago (should trigger incremental sync)
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twelveHoursAgo)

        let expectedError = NSError(domain: "incremental_sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Incremental sync failed"])
        mockIncrementalSyncService.startIncrementalSyncResult = .failure(expectedError)

        // When/Then
        await #expect(throws: expectedError) {
            try await sut.performSmartSync(for: sampleSiteID, isBackgroundSync: false)
        }
    }

    // MARK: - Full Sync State Monitoring Tests

    @Test func lastFullSyncState_returns_syncNeverDone_when_never_synced() async throws {
        // Given - no previous sync for this site
        // When - query state
        let state = await sut.loadLastFullSyncState(for: sampleSiteID)

        // Then - should return syncNeverDone
        #expect(state == .syncNeverDone(siteID: sampleSiteID))
    }

    @Test func lastFullSyncState_returns_syncCompleted_when_synced_before() async throws {
        // Given - previous sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-3600))

        // When - query state
        let state = await sut.loadLastFullSyncState(for: sampleSiteID)

        // Then - should return syncCompleted
        #expect(state == .syncCompleted(siteID: sampleSiteID))
    }

    @Test func fullSyncStateModel_emits_events_during_sync() async throws {
        // Given
        let expectedCatalog = POSCatalog(products: [], variations: [], syncDate: .now)
        mockSyncService.startFullSyncResult = .success(expectedCatalog)

        // When - start sync and stream collection concurrently
        try await sut.performFullSync(for: sampleSiteID)

        // Then - should emit syncStarted and syncCompleted with correct siteID
        let finalState = await sut.fullSyncStateModel.state[sampleSiteID]
        #expect(finalState == .syncCompleted(siteID: sampleSiteID))
    }

    // MARK: - Helper Methods

    private func createSiteInDatabase(siteID: Int64, lastFullSyncDate: Date? = nil, lastIncrementalSyncDate: Date? = nil) throws {
        try grdbManager.databaseConnection.write { db in
            let site = PersistedSite(id: siteID, lastCatalogIncrementalSyncDate: lastIncrementalSyncDate, lastCatalogFullSyncDate: lastFullSyncDate)
            try site.insert(db)
        }
    }
}

// MARK: - Mock Services

final class MockPOSCatalogFullSyncService: POSCatalogFullSyncServiceProtocol {
    var startFullSyncResult: Result<POSCatalog, Error> = .success(POSCatalog(products: [], variations: [], syncDate: .now))
    var syncDelay: UInt64 = 0 // nanoseconds to delay before returning

    // Controlled sync mechanism
    private var syncContinuations: [CheckedContinuation<Void, Never>] = []
    private var shouldBlockSync = false
    private var syncBlockedContinuations: [CheckedContinuation<Void, Never>] = []

    private(set) var startFullSyncCallCount = 0
    private(set) var lastSyncSiteID: Int64?
    private(set) var lastAllowCellular: Bool?

    func startFullSync(for siteID: Int64,
                        regenerateCatalog: Bool,
                        allowCellular: Bool,
                        isBackgroundSync: Bool) async throws -> POSCatalog {
        startFullSyncCallCount += 1
        lastSyncSiteID = siteID
        lastAllowCellular = allowCellular

        // If we should block, wait for continuation to be resumed
        if shouldBlockSync {
            await withCheckedContinuation { continuation in
                syncContinuations.append(continuation)
                // Signal that a sync is now blocked and ready
                if !syncBlockedContinuations.isEmpty {
                    syncBlockedContinuations.removeFirst().resume()
                }
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

    var parseAndPersistBackgroundDownloadResult: Result<POSCatalog, Error> = .success(POSCatalog(products: [], variations: [], syncDate: .now))
    private(set) var parseAndPersistBackgroundDownloadCallCount = 0
    private(set) var lastBackgroundDownloadFileURL: URL?
    private(set) var lastBackgroundDownloadSiteID: Int64?

    func parseAndPersistBackgroundDownload(fileURL: URL, siteID: Int64) async throws -> POSCatalog {
        parseAndPersistBackgroundDownloadCallCount += 1
        lastBackgroundDownloadFileURL = fileURL
        lastBackgroundDownloadSiteID = siteID

        switch parseAndPersistBackgroundDownloadResult {
        case .success(let catalog):
            return catalog
        case .failure(let error):
            throw error
        }
    }

    func blockNextSync() {
        shouldBlockSync = true
    }

    func waitUntilSyncBlocked() async {
        await withCheckedContinuation { continuation in
            syncBlockedContinuations.append(continuation)
        }
    }

    func resumeBlockedSync() {
        syncContinuations.forEach { $0.resume() }
        syncContinuations.removeAll()
        shouldBlockSync = false
    }
}

// MARK: - Sync Eligibility Tests

extension POSCatalogSyncCoordinatorTests {
    @Test func performSmartSync_skips_sync_when_catalog_is_ineligible() async throws {
        // Given
        let eligibilityChecker = MockPOSLocalCatalogEligibilityService()
        await eligibilityChecker.setIneligible(for: sampleSiteID)  // Catalog ineligible
        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: eligibilityChecker,
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When / Then - sync should be skipped
        await #expect(throws: POSCatalogSyncError.shouldNotSync) {
            try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)
        }

        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_proceeds_when_catalog_is_eligible_and_no_first_sync_date() async throws {
        // Given - new user, catalog eligible
        let eligibilityChecker = MockPOSLocalCatalogEligibilityService()
        await eligibilityChecker.setEligibility(.eligible, for: sampleSiteID)

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: eligibilityChecker,
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should proceed
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performSmartSync_records_first_sync_date_after_successful_sync() async throws {
        // Given - new user
        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - first sync date should be recorded
        #expect(mockSiteSettings.setFirstPOSCatalogSyncDateCalled == true)
        #expect(mockSiteSettings.mockFirstPOSCatalogSyncDate != nil)
    }

    @Test func performSmartSync_does_not_overwrite_existing_first_sync_date() async throws {
        // Given - existing user with first sync date
        let originalDate = Date().addingTimeInterval(-10 * 24 * 60 * 60) // 10 days ago
        mockSiteSettings.mockFirstPOSCatalogSyncDate = originalDate

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - first sync date should remain unchanged
        #expect(mockSiteSettings.mockFirstPOSCatalogSyncDate == originalDate)
    }

    @Test func performSmartSync_proceeds_with_incremental_sync_for_new_user_within_30_day_grace_period() async throws {
        // Given - user who first synced 15 days ago (within 30-day grace period)
        let fifteenDaysAgo = Date().addingTimeInterval(-15 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fifteenDaysAgo
        // No lastPOSOpenedDate set

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twoHoursAgo)
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should proceed (within grace period)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_skips_sync_for_existing_user_past_30_days_with_no_recent_open() async throws {
        // Given - user who first synced 40 days ago, never opened POS recently
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        // No lastPOSOpenedDate set

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should be skipped (past grace period, no recent open)
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_proceeds_for_existing_user_past_30_days_with_recent_open() async throws {
        // Given - user who first synced 40 days ago, but opened POS 5 days ago
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        let fiveDaysAgo = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        mockSiteSettings.mockPOSLastOpenedDate = fiveDaysAgo

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should proceed (opened recently)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_skips_sync_for_existing_user_past_30_days_with_stale_open() async throws {
        // Given - user who first synced 40 days ago, last opened POS 35 days ago (too long)
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        let thirtyFiveDaysAgo = Date().addingTimeInterval(-35 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        mockSiteSettings.mockPOSLastOpenedDate = thirtyFiveDaysAgo

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should be skipped (last opened too long ago)
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_boundary_test_exactly_30_days_after_first_sync_with_recent_open() async throws {
        // Given - user who first synced exactly 30 days ago, opened POS today
        let exactlyThirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = exactlyThirtyDaysAgo
        mockSiteSettings.mockPOSLastOpenedDate = Date()

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should proceed (opened recently, even though at 30-day boundary)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_boundary_test_exactly_30_days_since_last_open() async throws {
        // Given - user who first synced 40 days ago, opened POS exactly 30 days ago
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        let exactlyThirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        mockSiteSettings.mockPOSLastOpenedDate = exactlyThirtyDaysAgo

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID, isBackgroundSync: false)

        // Then - sync should proceed (exactly at 30-day boundary is still eligible)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performFullSyncIfApplicable_with_zero_maxAge_ignores_temporal_eligibility() async throws {
        // Given - user past 30-day grace period with no recent open (normally ineligible)
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        // No lastPOSOpenedDate set (never opened recently)

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fortyDaysAgo)
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When - maxAge is zero (forced sync, e.g. pull to refresh)
        try await coordinator.performFullSyncIfApplicable(for: sampleSiteID, maxAge: .zero)

        // Then - sync should proceed despite temporal ineligibility
        #expect(mockSyncService.startFullSyncCallCount == 1)
    }

    @Test func performIncrementalSyncIfApplicable_with_zero_maxAge_ignores_temporal_eligibility() async throws {
        // Given - user past 30-day grace period with no recent open (normally ineligible)
        let fortyDaysAgo = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        mockSiteSettings.mockFirstPOSCatalogSyncDate = fortyDaysAgo
        // No lastPOSOpenedDate set (never opened recently)

        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(),
            siteSettings: mockSiteSettings
        )
        // Set up database with full sync date (required for incremental sync)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fortyDaysAgo)
        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When - maxAge is zero (forced sync, e.g. after a purchase)
        try await coordinator.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: .zero)

        // Then - sync should proceed despite temporal ineligibility
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    // MARK: - isSyncStale Tests

    @Test func isSyncStale_returns_true_when_no_full_sync_performed() async throws {
        // Given - no full sync date set

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then
        #expect(isStale == true)
    }

    @Test func isSyncStale_returns_false_when_full_sync_is_recent() async throws {
        // Given - last full sync was 3 days ago
        let threeDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -3, to: Date()))
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: threeDaysAgo)

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then
        #expect(isStale == false)
    }

    @Test func isSyncStale_returns_true_when_full_sync_is_old() async throws {
        // Given - last full sync was 10 days ago
        let tenDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -10, to: Date()))
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: tenDaysAgo)

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then
        #expect(isStale == true)
    }

    @Test func isSyncStale_ignores_incremental_sync_date() async throws {
        // Given - incremental sync was recent, but full sync was old
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let tenDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -10, to: Date()))
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: tenDaysAgo, lastIncrementalSyncDate: yesterday)

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then - should only check full sync date
        #expect(isStale == true)
    }

    @Test func isSyncStale_boundary_within_threshold() async throws {
        // Given - last full sync was 6 days and 23 hours ago (just under 7 days)
        let justUnderSevenDays = try #require(Calendar.current.date(byAdding: .day, value: -6, to: Date()))
            .addingTimeInterval(-23 * 60 * 60) // minus 23 hours
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: justUnderSevenDays)

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then - just under threshold should not be stale
        #expect(isStale == false)
    }

    @Test func isSyncStale_boundary_past_threshold() async throws {
        // Given - last full sync was 7 days and 1 second ago (just past 7 days)
        let justPastSevenDays = try #require(Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            .addingTimeInterval(-1)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: justPastSevenDays)

        // When
        let isStale = await sut.isSyncStale(for: sampleSiteID, maxDays: 7)

        // Then - past threshold should be stale
        #expect(isStale == true)
    }

    // MARK: - Stop Ongoing Syncs Tests

    @Test func stopOngoingSyncs_clears_incremental_sync_tracking() async throws {
        // Given - start an incremental sync
        let fullSyncDate = Date().addingTimeInterval(-3600)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate)
        mockIncrementalSyncService.blockNextSync()

        let syncTask = Task {
            try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        }

        // Wait until sync is actually blocked
        await mockIncrementalSyncService.waitUntilSyncBlocked()

        // When - stop ongoing syncs
        await sut.stopOngoingSyncs(for: sampleSiteID)

        // Then - incremental sync tracking should be cleared
        // Attempting to start another sync should succeed (not throw syncAlreadyInProgress)
        mockIncrementalSyncService.resumeBlockedSync()
        _ = try? await syncTask.value

        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 2)
    }

    @Test func stopOngoingSyncs_updates_full_sync_state_when_sync_in_progress() async throws {
        // Given - start a full sync
        mockSyncService.blockNextSync()
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        let syncTask = Task {
            try await sut.performFullSync(for: sampleSiteID)
        }

        // Wait until sync is actually blocked
        await mockSyncService.waitUntilSyncBlocked()

        // Verify sync is in progress
        let stateBeforeStop = await sut.loadLastFullSyncState(for: sampleSiteID)
        let isSyncInProgress: Bool = switch stateBeforeStop {
        case .initialSyncStarted, .syncStarted: true
        default: false
        }
        #expect(isSyncInProgress)

        // When - stop ongoing syncs
        await sut.stopOngoingSyncs(for: sampleSiteID)

        // Then - sync state should be updated to failed with requestCancelled
        let stateAfterStop = await sut.loadLastFullSyncState(for: sampleSiteID)
        let isFailed: Bool = switch stateAfterStop {
        case .syncFailed(let siteID, let error):
            siteID == sampleSiteID && (error as? POSCatalogSyncError) == .requestCancelled
        case .initialSyncFailed(let siteID, let error):
            siteID == sampleSiteID && (error as? POSCatalogSyncError) == .requestCancelled
        default: false
        }
        #expect(isFailed)

        // Cleanup
        mockSyncService.resumeBlockedSync()
        _ = try? await syncTask.value
    }

    @Test func stopOngoingSyncs_does_nothing_when_no_sync_in_progress() async throws {
        // Given - no sync in progress
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-3600))

        let stateBeforeStop = await sut.loadLastFullSyncState(for: sampleSiteID)

        // When - stop ongoing syncs
        await sut.stopOngoingSyncs(for: sampleSiteID)

        // Then - state should remain unchanged
        let stateAfterStop = await sut.loadLastFullSyncState(for: sampleSiteID)
        #expect(stateBeforeStop == stateAfterStop)
    }

    @Test func stopOngoingSyncs_handles_different_sites_independently() async throws {
        // Given - syncs for two different sites
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let fullSyncDate = Date().addingTimeInterval(-3600)

        try createSiteInDatabase(siteID: siteA, lastFullSyncDate: fullSyncDate)
        try createSiteInDatabase(siteID: siteB, lastFullSyncDate: fullSyncDate)

        mockIncrementalSyncService.blockNextSync()

        // Start syncs for both sites
        let syncTaskA = Task {
            try await sut.performIncrementalSyncIfApplicable(for: siteA, maxAge: sampleMaxAge)
        }

        // Wait for first sync to block
        await mockIncrementalSyncService.waitUntilSyncBlocked()

        // Now start second sync (will also block since shouldBlockSync is still true)
        let syncTaskB = Task {
            try await sut.performIncrementalSyncIfApplicable(for: siteB, maxAge: sampleMaxAge)
        }

        // Wait for second sync to block
        await mockIncrementalSyncService.waitUntilSyncBlocked()

        // When - stop syncs only for siteA
        await sut.stopOngoingSyncs(for: siteA)

        // Then - siteB sync should still throw syncAlreadyInProgress
        await #expect(throws: POSCatalogSyncError.syncAlreadyInProgress(siteID: siteB)) {
            try await sut.performIncrementalSyncIfApplicable(for: siteB, maxAge: sampleMaxAge)
        }

        // But siteA should allow new sync
        mockIncrementalSyncService.resumeBlockedSync()
        _ = try? await syncTaskA.value
        _ = try? await syncTaskB.value

        mockIncrementalSyncService.startIncrementalSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))
        try await sut.performIncrementalSyncIfApplicable(for: siteA, maxAge: sampleMaxAge)
    }

    // MARK: - Cellular Data Tests

    @Test func performFullSync_allows_cellular_for_first_sync() async throws {
        // Given - No previous sync (first sync)
        mockSiteSettings.mockPOSLocalCatalogCellularDataAllowed = false

        // When
        try await sut.performFullSync(for: sampleSiteID)

        // Then - Should allow cellular for first sync regardless of setting
        #expect(mockSyncService.lastAllowCellular == true)
    }

    @Test func performFullSync_respects_cellular_setting_for_subsequent_syncs_when_true() async throws {
        // Given - Previous sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockSiteSettings.mockPOSLocalCatalogCellularDataAllowed = true

        // When
        try await sut.performFullSync(for: sampleSiteID, regenerateCatalog: true)

        // Then - Should use the setting value
        #expect(mockSyncService.lastAllowCellular == true)
        #expect(mockSiteSettings.getPOSLocalCatalogCellularDataAllowedCalled == true)
    }

    @Test func performFullSync_respects_cellular_setting_for_subsequent_syncs_when_false() async throws {
        // Given - Previous sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockSiteSettings.mockPOSLocalCatalogCellularDataAllowed = false

        // When
        try await sut.performFullSync(for: sampleSiteID, regenerateCatalog: true)

        // Then - Should use the setting value
        #expect(mockSyncService.lastAllowCellular == false)
        #expect(mockSiteSettings.getPOSLocalCatalogCellularDataAllowedCalled == true)
    }

    @Test func performFullSync_allows_cellular_for_first_sync_even_when_setting_is_false() async throws {
        // Given - No previous sync AND setting is explicitly false
        mockSiteSettings.mockPOSLocalCatalogCellularDataAllowed = false

        // When
        try await sut.performFullSync(for: sampleSiteID)

        // Then - Should allow cellular for first sync, overriding the setting
        #expect(mockSyncService.lastAllowCellular == true)
        // Setting should not be checked for first sync (it's overridden)
    }

    // MARK: - Analytics Tests

    @Test func performFullSyncIfApplicable_tracks_analytics_events() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )

        // When
        try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then - Verify sync started event
        let syncStarted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_started" }
        #expect(syncStarted != nil)

        // Then - Verify sync completed event
        let syncCompleted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_completed" }
        #expect(syncCompleted != nil)
    }

    @Test func performFullSyncIfApplicable_tracks_synced_product_and_variation_counts() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )

        // Set up mock to return a catalog with specific counts
        let syncedProducts = [POSProduct.fake(), POSProduct.fake(), POSProduct.fake()]
        let syncedVariations = [POSProductVariation.fake()]
        mockSyncService.startFullSyncResult = .success(
            POSCatalog(products: syncedProducts, variations: syncedVariations, syncDate: .now)
        )

        // When
        try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncCompleted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_completed" }
        #expect(syncCompleted != nil)
        #expect(syncCompleted?.properties?["products_synced"] as? String == "3")
        #expect(syncCompleted?.properties?["variations_synced"] as? String == "1")
    }

    @Test func performFullSyncIfApplicable_tracks_sync_failed_with_error_type() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        mockSyncService.startFullSyncResult = .failure(NSError(domain: "NetworkingCore.NetworkError", code: 500))

        // When
        try? await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncFailed = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_failed" }
        #expect(syncFailed != nil)
        #expect(syncFailed?.properties?["error_type"] as? String == "network_error")
    }

    @Test func performFullSyncIfApplicable_tracks_database_error_type() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        // Simulate a GRDB database error by using domain "GRDB.DatabaseError"
        mockSyncService.startFullSyncResult = .failure(NSError(domain: "GRDB.DatabaseError", code: 1))

        // When
        try? await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncFailed = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_failed" }
        #expect(syncFailed != nil)
        #expect(syncFailed?.properties?["error_type"] as? String == "database_error")
    }

    @Test func performFullSyncIfApplicable_tracks_insufficient_space_for_sqlite_full_error() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        // Simulate SQLITE_FULL error (code 13 = disk full)
        mockSyncService.startFullSyncResult = .failure(NSError(domain: "GRDB.DatabaseError", code: 13))

        // When
        try? await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncFailed = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_failed" }
        #expect(syncFailed != nil)
        #expect(syncFailed?.properties?["error_type"] as? String == "insufficient_free_space")
    }

    @Test func performIncrementalSyncIfApplicable_tracks_analytics_events() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-30 * 60))

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncStarted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_started" }
        #expect(syncStarted != nil)
        let syncCompleted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_completed" }
        #expect(syncCompleted != nil)
    }

    @Test func performIncrementalSyncIfApplicable_tracks_synced_product_and_variation_counts() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-30 * 60))

        // Set up mock to return a catalog with specific counts
        let syncedProducts = [POSProduct.fake(), POSProduct.fake()]
        let syncedVariations = [POSProductVariation.fake(), POSProductVariation.fake(), POSProductVariation.fake()]
        mockIncrementalSyncService.startIncrementalSyncResult = .success(
            POSCatalog(products: syncedProducts, variations: syncedVariations, syncDate: .now)
        )

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncCompleted = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_completed" }
        #expect(syncCompleted != nil)
        #expect(syncCompleted?.properties?["products_synced"] as? String == "2")
        #expect(syncCompleted?.properties?["variations_synced"] as? String == "3")
    }

    @Test func performIncrementalSyncIfApplicable_tracks_sync_skipped_when_no_full_sync() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        // No full sync exists for this site

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncSkipped = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_skipped" }
        #expect(syncSkipped != nil)
        #expect(syncSkipped?.properties?["reason"] as? String == "no_full_sync")
        #expect(syncSkipped?.properties?["sync_type"] as? String == "incremental")
    }

    @Test func performFullSyncIfApplicable_tracks_sync_skipped_when_not_stale() async throws {
        // Given
        let mockAnalytics = MockAnalytics()
        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics
        )
        // Recent sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date())

        // When
        try? await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
        let syncSkipped = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_skipped" }
        #expect(syncSkipped != nil)
        #expect(syncSkipped?.properties?["reason"] as? String == "catalog_not_stale")
        #expect(syncSkipped?.properties?["sync_type"] as? String == "full")
    }

    // MARK: - Sync Type Analytics

    @Test("POSCatalogSyncType enum has correct raw values")
    func testPOSCatalogSyncTypeRawValues() {
        #expect(POSCatalogSyncType.full.rawValue == "full")
        #expect(POSCatalogSyncType.incremental.rawValue == "incremental")
    }

    // MARK: - POS Not Opened 30 Days Skip Reason Tests

    @Test func performFullSyncIfApplicable_tracks_pos_not_opened_30_days_when_not_opened_recently() async throws {
        // Given - Store with first sync > 30 days ago and last opened > 30 days ago
        let mockAnalytics = MockAnalytics()
        let mockSiteSettings = MockSiteSpecificAppSettingsStoreMethods()

        // Set first sync date to 40 days ago
        let firstSyncDate = Calendar.current.date(byAdding: .day, value: -40, to: Date())!
        mockSiteSettings.setFirstPOSCatalogSyncDate(siteID: sampleSiteID, date: firstSyncDate)

        // Set last opened date to 35 days ago (more than 30 days)
        let lastOpenedDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())!
        mockSiteSettings.setPOSLastOpenedDate(siteID: sampleSiteID, date: lastOpenedDate)

        // Create site in database with full sync date
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: firstSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics,
            connectivityObserver: nil
        )

        // When - Try to perform sync with non-zero maxAge (temporal criteria are checked)
        // Note: maxAge of .zero would bypass temporal eligibility checks
        try? await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then - Should track pos_not_opened_30_days
        let syncSkipped = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_skipped" }
        #expect(syncSkipped != nil)
        #expect(syncSkipped?.properties?["reason"] as? String == "pos_not_opened_30_days")
        #expect(syncSkipped?.properties?["sync_type"] as? String == "full")
    }

    @Test func performIncrementalSyncIfApplicable_tracks_pos_not_opened_30_days_when_never_opened_and_past_grace_period() async throws {
        // Given - Store with first sync > 30 days ago and never opened POS
        let mockAnalytics = MockAnalytics()
        let mockSiteSettings = MockSiteSpecificAppSettingsStoreMethods()

        // Set first sync date to 40 days ago
        let firstSyncDate = Calendar.current.date(byAdding: .day, value: -40, to: Date())!
        mockSiteSettings.setFirstPOSCatalogSyncDate(siteID: sampleSiteID, date: firstSyncDate)

        // Don't set last opened date (nil = never opened)

        // Create site in database with full sync date
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: firstSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings,
            analytics: mockAnalytics,
            connectivityObserver: nil
        )

        // When - Try to perform incremental sync with non-zero maxAge (temporal criteria are checked)
        // Note: maxAge of .zero would bypass temporal eligibility checks
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then - Should track pos_not_opened_30_days
        let syncSkipped = mockAnalytics.trackedEvents.first { $0.eventName == "local_catalog_sync_skipped" }
        #expect(syncSkipped != nil)
        #expect(syncSkipped?.properties?["reason"] as? String == "pos_not_opened_30_days")
        #expect(syncSkipped?.properties?["sync_type"] as? String == "incremental")
    }
}

// MARK: - FTS Rebuild Tests

extension POSCatalogSyncCoordinatorTests {
    private func createSyncCoordinator() -> POSCatalogSyncCoordinator {
        POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: mockEligibilityChecker,
            siteSettings: mockSiteSettings
        )
    }

    @Test("startBackgroundFTSRebuildIfNeeded starts rebuild when index empty but products exist")
    func test_startBackgroundFTSRebuildIfNeeded_starts_rebuild_when_needed() async throws {
        // Given: Products exist but FTS index is empty
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: sampleSiteID).insert(db)
            let product = PersistedProduct(
                id: 100,
                siteID: sampleSiteID,
                name: "Test Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "10.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try product.insert(db)
        }

        let sut = createSyncCoordinator()

        // When: Start background rebuild and wait for completion
        await sut.startBackgroundFTSRebuildIfNeeded(for: sampleSiteID)
        await sut.awaitBackgroundFTSRebuild(for: sampleSiteID)

        // Then: FTS index is populated
        let results = try await grdbManager.databaseConnection.read { db in
            try POSSearchIndexBuilder.search(siteID: sampleSiteID, term: "Test", in: db)
        }
        #expect(results.count == 1)
    }
}

extension POSCatalogSyncCoordinator {
    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        try await performFullSyncIfApplicable(for: siteID, maxAge: maxAge, regenerateCatalog: false, isBackgroundSync: false)
    }
}
