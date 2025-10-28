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

        // When - max age is 1 hour
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then
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

        // When
        let _ = try await sut.performFullSyncIfApplicable(for: siteA, maxAge: 2 * sampleMaxAge)
        let _ = try await sut.performFullSyncIfApplicable(for: siteB, maxAge: 2 * sampleMaxAge)

        // Then
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
        let _ = try await sut.performFullSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)

        // Then - should not sync because site exists and time hasn't passed
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
        let maxAge: TimeInterval = 2
        let incrementalSyncDate = Date().addingTimeInterval(-(maxAge - 0.2)) // Just within max age
        let fullSyncDate = Date().addingTimeInterval(-7200)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: fullSyncDate, lastIncrementalSyncDate: incrementalSyncDate)

        let sut = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService()
        )

        // When
        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: maxAge)

        // Then
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
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService()
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
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService()
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

        // Give first sync a moment to start and get blocked
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // When - try to start second incremental sync while first is blocked
        do {
            _ = try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
            #expect(Bool(false), "Should have thrown syncAlreadyInProgress error")
        } catch let error as POSCatalogSyncError {
            // Then
            #expect(error == POSCatalogSyncError.syncAlreadyInProgress(siteID: sampleSiteID))
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
        mockIncrementalSyncService.startIncrementalSyncResult = .success(())

        try await sut.performIncrementalSyncIfApplicable(for: sampleSiteID, maxAge: sampleMaxAge)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 2)
    }

    // MARK: - Smart Sync Tests

    @Test func performSmartSync_performs_full_sync_when_last_full_sync_older_than_threshold() async throws {
        // Given - last full sync was 25 hours ago (older than 24 hour threshold)
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twentyFiveHoursAgo)

        // When
        try await sut.performSmartSync(for: sampleSiteID)

        // Then - should perform full sync
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_performs_incremental_sync_when_last_full_sync_within_threshold() async throws {
        // Given - last full sync was 12 hours ago (within 24 hour threshold)
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twelveHoursAgo)

        // When
        try await sut.performSmartSync(for: sampleSiteID)

        // Then - should perform incremental sync
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }

    @Test func performSmartSync_performs_full_sync_when_no_previous_sync() async throws {
        // Given - no previous sync exists
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)

        // When
        try await sut.performSmartSync(for: sampleSiteID)

        // Then - should perform full sync
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_respects_custom_fullSyncMaxAge() async throws {
        // Given - last full sync was 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: twoHoursAgo)

        // When - using custom threshold of 1 hour
        let oneHour: TimeInterval = 60 * 60
        try await sut.performSmartSync(for: sampleSiteID, fullSyncMaxAge: oneHour)

        // Then - should perform full sync because last sync is older than 1 hour
        #expect(mockSyncService.startFullSyncCallCount == 1)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_performs_incremental_sync_with_custom_threshold() async throws {
        // Given - last full sync was 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: thirtyMinutesAgo)

        // When - using custom threshold of 1 hour
        let oneHour: TimeInterval = 60 * 60
        try await sut.performSmartSync(for: sampleSiteID, fullSyncMaxAge: oneHour)

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
            try await sut.performSmartSync(for: sampleSiteID)
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
            try await sut.performSmartSync(for: sampleSiteID)
        }
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

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

        // Then - sync should be skipped
        #expect(mockSyncService.startFullSyncCallCount == 0)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 0)
    }

    @Test func performSmartSync_proceeds_when_catalog_is_eligible_and_no_first_sync_date() async throws {
        // Given - new user, catalog eligible
        let coordinator = POSCatalogSyncCoordinator(
            fullSyncService: mockSyncService,
            incrementalSyncService: mockIncrementalSyncService,
            grdbManager: grdbManager,
            catalogEligibilityChecker: MockPOSLocalCatalogEligibilityService(), // Catalog eligible
            siteSettings: mockSiteSettings
        )
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: nil)
        mockSyncService.startFullSyncResult = .success(POSCatalog(products: [], variations: [], syncDate: .now))

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        try await coordinator.performSmartSync(for: sampleSiteID)

        // Then - first sync date should remain unchanged
        #expect(mockSiteSettings.mockFirstPOSCatalogSyncDate == originalDate)
    }

    @Test func performSmartSync_proceeds_for_new_user_within_30_day_grace_period() async throws {
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
        try createSiteInDatabase(siteID: sampleSiteID, lastFullSyncDate: Date().addingTimeInterval(-2 * 60 * 60))
        mockIncrementalSyncService.startIncrementalSyncResult = .success(())

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        mockIncrementalSyncService.startIncrementalSyncResult = .success(())

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        mockIncrementalSyncService.startIncrementalSyncResult = .success(())

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

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
        mockIncrementalSyncService.startIncrementalSyncResult = .success(())

        // When
        try await coordinator.performSmartSync(for: sampleSiteID)

        // Then - sync should proceed (exactly at 30-day boundary is still eligible)
        #expect(mockIncrementalSyncService.startIncrementalSyncCallCount == 1)
    }
}
