import Foundation
import PointOfSale
import Testing
import UIKit
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct POSTabCoordinatorTests {
    private let siteID: Int64 = 123

    @Test func resolveLocalCatalogAvailability_uses_completed_full_sync_when_cached_tab_is_visible() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: true)
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncCompleted(siteID: siteID))
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .ineligible(reason: .noInternetConnection)
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == true)
        #expect(eligibilityChecker.checkEligibilityCallCount == 0)
    }

    @Test func resolveLocalCatalogAvailability_uses_previous_full_sync_when_latest_sync_failed() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: true)
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(
            syncState: .syncFailed(siteID: siteID, error: NSError(domain: "test", code: 0)),
            hoursSinceLastSyncResult: 1
        )
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .ineligible(reason: .noInternetConnection)
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == true)
        #expect(eligibilityChecker.checkEligibilityCallCount == 0)
    }

    @Test func resolveLocalCatalogAvailability_returns_false_when_cached_tab_is_visible_but_catalog_never_synced() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: true)
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncNeverDone(siteID: siteID))
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .ineligible(reason: .noInternetConnection)
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == false)
        #expect(eligibilityChecker.checkEligibilityCallCount == 1)
    }

    @Test func resolveLocalCatalogAvailability_does_not_check_remote_eligibility_when_offline_and_catalog_never_synced() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: true)
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncNeverDone(siteID: siteID))
        let eligibilityChecker = MockPOSEligibilityChecker()
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator,
                          connectivityObserver: connectivityObserver)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == false)
        #expect(eligibilityChecker.checkEligibilityCallCount == 0)
    }

    @Test func resolveLocalCatalogAvailability_returns_false_when_cached_tab_is_not_visible() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: false)
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncCompleted(siteID: siteID))
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .ineligible(reason: .noInternetConnection)
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == false)
        #expect(eligibilityChecker.checkEligibilityCallCount == 1)
    }

    @Test func resolveLocalCatalogAvailability_uses_online_eligibility_when_cached_local_catalog_entry_is_unavailable() async throws {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        let catalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncNeverDone(siteID: siteID))
        let localCatalogEligibilityService = MockPOSTabLocalCatalogEligibilityService(eligibilityState: .eligible)
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .eligible
        let sut = makeSUT(eligibilityService: eligibilityService,
                          eligibilityChecker: eligibilityChecker,
                          catalogSyncCoordinator: catalogSyncCoordinator,
                          localCatalogEligibilityService: localCatalogEligibilityService)

        // When
        let result = await sut.resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

        // Then
        #expect(result == true)
        #expect(eligibilityChecker.checkEligibilityCallCount == 1)
        #expect(await localCatalogEligibilityService.updatePOSEligibilityCallCount == 1)
    }

    @Test func updatePOSEligibility_does_not_refresh_local_catalog_ineligibility_when_offline() async throws {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        let eligibilityChecker = MockPOSEligibilityChecker()
        eligibilityChecker.eligibility = .ineligible(reason: .noInternetConnection)
        let localCatalogEligibilityService = MockPOSTabLocalCatalogEligibilityService()
        let sut = makeSUT(eligibilityChecker: eligibilityChecker,
                          localCatalogEligibilityService: localCatalogEligibilityService,
                          connectivityObserver: connectivityObserver)

        // When
        sut.updatePOSEligibility(isPOSTabVisible: true)
        await Task.yield()
        await Task.yield()

        // Then
        #expect(eligibilityChecker.checkEligibilityCallCount == 0)
        #expect(await localCatalogEligibilityService.updatePOSEligibilityCallCount == 0)
    }

    @Test func preferredConnectionMethod_returns_bluetooth_without_checking_tap_to_pay_for_offline_local_catalog_entry() async throws {
        // Given
        let tapToPayChecker = MockPOSTabTapToPayAvailabilityChecker(result: .available)
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        let sut = makeSUT(connectivityObserver: connectivityObserver,
                          userInterfaceIdiom: .phone)

        // When
        let result = await sut.preferredConnectionMethodForPOSEntry(isLocalCatalogEligible: true,
                                                                    tapToPayAvailabilityChecker: tapToPayChecker)

        // Then
        #expect(result == .bluetooth)
        #expect(tapToPayChecker.checkAvailabilityCallCount == 0)
    }

    @Test func preferredConnectionMethod_checks_tap_to_pay_for_online_local_catalog_entry_on_phone() async throws {
        // Given
        let tapToPayChecker = MockPOSTabTapToPayAvailabilityChecker(result: .available)
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))
        let sut = makeSUT(connectivityObserver: connectivityObserver,
                          userInterfaceIdiom: .phone)

        // When
        let result = await sut.preferredConnectionMethodForPOSEntry(isLocalCatalogEligible: true,
                                                                    tapToPayAvailabilityChecker: tapToPayChecker)

        // Then
        #expect(result == .tapToPay)
        #expect(tapToPayChecker.checkAvailabilityCallCount == 1)
    }

    @Test func preferredConnectionMethod_returns_bluetooth_without_checking_tap_to_pay_on_ipad() async throws {
        // Given
        let tapToPayChecker = MockPOSTabTapToPayAvailabilityChecker(result: .available)
        let sut = makeSUT(userInterfaceIdiom: .pad)

        // When
        let result = await sut.preferredConnectionMethodForPOSEntry(isLocalCatalogEligible: false,
                                                                    tapToPayAvailabilityChecker: tapToPayChecker)

        // Then
        #expect(result == .bluetooth)
        #expect(tapToPayChecker.checkAvailabilityCallCount == 0)
    }
}

private extension POSTabCoordinatorTests {
    func makeSUT(eligibilityService: MockPOSEligibilityService = MockPOSEligibilityService(),
                 eligibilityChecker: MockPOSEligibilityChecker = MockPOSEligibilityChecker(),
                 catalogSyncCoordinator: MockPOSTabCatalogSyncCoordinator = MockPOSTabCatalogSyncCoordinator(syncState: .syncCompleted(siteID: 123)),
                 localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol? = MockPOSTabLocalCatalogEligibilityService(),
                 connectivityObserver: MockConnectivityObserver = MockConnectivityObserver(),
                 userInterfaceIdiom: UIUserInterfaceIdiom = .pad) -> POSTabCoordinator {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: .fake().copy(siteID: siteID)))
        stores.updateDefaultStore(storeID: siteID)
        stores.testPOSCatalogSyncCoordinator = catalogSyncCoordinator
        if case .unknown = connectivityObserver.currentStatus {
            connectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))
        }

        return POSTabCoordinator(
            siteID: siteID,
            tabContainerController: TabContainerController(),
            viewControllerToPresent: UIViewController(),
            storesManager: stores,
            eligibilityChecker: eligibilityChecker,
            eligibilityService: eligibilityService,
            connectivityObserver: connectivityObserver,
            userInterfaceIdiom: userInterfaceIdiom,
            localCatalogEligibilityService: localCatalogEligibilityService
        )
    }
}

private final class MockPOSTabTapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking {
    private let result: POSTapToPayAvailabilityState
    private(set) var checkAvailabilityCallCount = 0

    init(result: POSTapToPayAvailabilityState) {
        self.result = result
    }

    func checkAvailability() async -> POSTapToPayAvailabilityState {
        checkAvailabilityCallCount += 1
        return result
    }
}

private actor MockPOSTabLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let eligibilityState: POSLocalCatalogEligibilityState
    private(set) var updatePOSEligibilityCallCount = 0

    init(eligibilityState: POSLocalCatalogEligibilityState = .eligible) {
        self.eligibilityState = eligibilityState
    }

    func catalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        eligibilityState
    }

    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async {
        updatePOSEligibilityCallCount += 1
    }

    func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        eligibilityState
    }
}

private final class MockPOSTabCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    let fullSyncStateModel = POSCatalogSyncStateModel()
    private let syncState: POSCatalogSyncState
    private let hoursSinceLastSyncResult: Int?

    init(syncState: POSCatalogSyncState, hoursSinceLastSyncResult: Int? = nil) {
        self.syncState = syncState
        self.hoursSinceLastSyncResult = hoursSinceLastSyncResult
    }

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool, isBackgroundSync: Bool) async throws {}

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {}

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval, isBackgroundSync: Bool) async throws {}

    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        syncState
    }

    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        false
    }

    func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        hoursSinceLastSyncResult
    }

    func stopOngoingSyncs(for siteID: Int64) async {}

    func processBackgroundDownload(fileURL: URL, siteID: Int64, snapshotDate: Date) async throws {}

    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {}

    func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async {}
}
