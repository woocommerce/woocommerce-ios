import Foundation
import Testing
@testable import Yosemite
import Storage

struct POSCatalogSyncCoordinatorTests {
    private let mockSyncService: MockPOSCatalogFullSyncService
    private let mockSettingsStore: MockSiteSpecificAppSettingsStoreMethods
    private let sut: POSCatalogSyncCoordinator
    private let sampleSiteID: Int64 = 134

    init() {
        self.mockSyncService = MockPOSCatalogFullSyncService()
        self.mockSettingsStore = MockSiteSpecificAppSettingsStoreMethods()
        self.sut = POSCatalogSyncCoordinator(
            syncService: mockSyncService,
            settingsStore: mockSettingsStore
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

    @Test func shouldPerformFullSync_returns_true_when_no_previous_sync() {
        // Given - no previous sync date stored
        mockSettingsStore.storedDates = [:]

        // When
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 3600)

        // Then
        #expect(shouldSync == true)
        #expect(mockSettingsStore.getPOSLastFullSyncDateCallCount == 1)
    }

    @Test func shouldPerformFullSync_returns_true_when_sync_is_stale() {
        // Given - previous sync was 2 hours ago
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)
        mockSettingsStore.storedDates[sampleSiteID] = twoHoursAgo

        // When - max age is 1 hour
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == true)
    }

    @Test func shouldPerformFullSync_returns_false_when_sync_is_fresh() {
        // Given - previous sync was 30 minutes ago
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        mockSettingsStore.storedDates[sampleSiteID] = thirtyMinutesAgo

        // When - max age is 1 hour
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 60 * 60)

        // Then
        #expect(shouldSync == false)
    }

    @Test func shouldPerformFullSync_handles_different_sites_independently() {
        // Given
        let siteA: Int64 = 123
        let siteB: Int64 = 456
        let oneHourAgo = Date().addingTimeInterval(-60 * 60)

        mockSettingsStore.storedDates[siteA] = oneHourAgo // Has previous sync
        // siteB has no previous sync

        // When
        let shouldSyncA = sut.shouldPerformFullSync(for: siteA, maxAge: 2 * 60 * 60) // 2 hours
        let shouldSyncB = sut.shouldPerformFullSync(for: siteB, maxAge: 2 * 60 * 60) // 2 hours

        // Then
        #expect(shouldSyncA == false) // Recent sync exists
        #expect(shouldSyncB == true)  // No previous sync
    }

    @Test func shouldPerformFullSync_with_zero_maxAge_always_returns_true() {
        // Given - previous sync was just now
        let justNow = Date()
        mockSettingsStore.storedDates[sampleSiteID] = justNow

        // When - max age is 0 (always sync)
        let shouldSync = sut.shouldPerformFullSync(for: sampleSiteID, maxAge: 0)

        // Then
        #expect(shouldSync == true)
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

