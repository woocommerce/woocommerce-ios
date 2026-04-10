import Testing
import Foundation
import Yosemite
@testable import WooCommerce
import UIKit

@MainActor
struct ForegroundPOSCatalogSyncDispatcherTests {
    private let timerProvider = MockDispatchTimerProvider()
    private let featureFlags = MockFeatureFlagService()
    private let notificationCenter = NotificationCenter()
    private let storeProvider = MockPOSCatalogStoreProvider()
    private let sut: ForegroundPOSCatalogSyncDispatcher
    private let coordinator = MockPOSCatalogSyncCoordinator()

    init() {
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleLocalCatalogi1] = true
        storeProvider.defaultStoreID = 123
        storeProvider.posCatalogSyncCoordinator = coordinator
        sut = ForegroundPOSCatalogSyncDispatcher(
            notificationCenter: notificationCenter,
            timerProvider: timerProvider,
            featureFlagService: featureFlags,
            storeProvider: storeProvider,
            isAppActive: { true }
        )
    }

    @Test
    func start_whenFeatureFlagEnabled_createsTimer() async throws {
        // When
        await sut.start()

        // Then
        #expect(timerProvider.createdTimers.count == 1)
        #expect(timerProvider.createdTimers.first?.isResumed == true)
    }

    @Test
    func start_whenFeatureFlagDisabled_doesNotCreateTimer() async throws {
        // Given
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleLocalCatalogi1] = false

        // When
        await sut.start()

        // Then
        #expect(timerProvider.createdTimers.isEmpty)
    }

    @Test
    func timerFires_whenRequirementsMet_triggersSync() async throws {
        // Given
        await sut.start()
        let timer = try #require(timerProvider.createdTimers.first)

        // When - fire timer and wait for sync to be called
        await withCheckedContinuation { continuation in
            coordinator.onPerformSmartSyncCalled = {
                continuation.resume()
            }
            timer.fire()
        }

        // Then
        #expect(coordinator.performSmartSyncInvocationCount == 1)
        #expect(coordinator.performSmartSyncSiteID == 123)
    }

    @Test
    func timerFires_whenNoDefaultStore_skipsSync() async throws {
        // Given
        storeProvider.defaultStoreID = nil

        await sut.start()
        let timer = try #require(timerProvider.createdTimers.first)

        // When
        timer.fire()

        // Then
        #expect(coordinator.performSmartSyncInvocationCount == 0)
    }

    @Test
    func coordinatorError_whenSyncAlreadyInProgress_logsButDoesNotCrash() async throws {
        // Given
        coordinator.performSmartSyncResult = .failure(POSCatalogSyncError.syncAlreadyInProgress(siteID: 123))

        await sut.start()
        let timer = try #require(timerProvider.createdTimers.first)

        // When - fire timer and wait for sync to be called
        await withCheckedContinuation { continuation in
            coordinator.onPerformSmartSyncCalled = {
                continuation.resume()
            }
            timer.fire()
        }

        // Then
        #expect(coordinator.performSmartSyncInvocationCount == 1)
    }

    @Test
    func start_whenSiteChanges_resetsAndRestartsSync() async throws {
        // Given - start with site 123
        await sut.start()
        let firstTimer = try #require(timerProvider.createdTimers.first)
        #expect(timerProvider.createdTimers.count == 1)

        // When - change site to 456 and start again
        storeProvider.defaultStoreID = 456
        await sut.start()

        // Then - old timer cancelled, new timer created
        #expect(firstTimer.isCancelled == true)
        #expect(timerProvider.createdTimers.count == 2)
        #expect(timerProvider.createdTimers.last?.isResumed == true)

        // Verify sync uses new site ID
        let newCoordinator = MockPOSCatalogSyncCoordinator()
        storeProvider.posCatalogSyncCoordinator = newCoordinator
        let newTimer = try #require(timerProvider.createdTimers.last)

        await withCheckedContinuation { continuation in
            newCoordinator.onPerformSmartSyncCalled = {
                continuation.resume()
            }
            newTimer.fire()
        }

        #expect(newCoordinator.performSmartSyncSiteID == 456)
    }

    @Test
    func defaultSiteNotification_stopsDispatcher() async throws {
        // Given
        await sut.start()
        let timer = try #require(timerProvider.createdTimers.first)
        #expect(timer.isResumed == true)

        // When - default site changes
        await withCheckedContinuation { continuation in
            timer.onCancelled = { continuation.resume() }

            notificationCenter.post(name: .StoresManagerDidUpdateDefaultSite, object: nil)
        }

        // Verify dispatcher can restart after notification
        await sut.start()
        #expect(timerProvider.createdTimers.count == 2)
        #expect(timerProvider.createdTimers.last?.isResumed == true)
    }

    @Test
    func didBecomeActiveNotification_startsTimer() async throws {
        // Given - dispatcher started but app not active initially
        let inactiveDispatcher = ForegroundPOSCatalogSyncDispatcher(
            notificationCenter: notificationCenter,
            timerProvider: timerProvider,
            featureFlagService: featureFlags,
            storeProvider: storeProvider,
            isAppActive: { false }
        )
        await inactiveDispatcher.start()

        // Then - no timer created yet
        #expect(timerProvider.createdTimers.isEmpty)

        // When - app becomes active, wait for timer to be created and resume
        await withCheckedContinuation { continuation in
            timerProvider.onTimerCreated = { $0.onResume = { continuation.resume() } }

            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        // Then - timer should be created and started
        #expect(timerProvider.createdTimers.count == 1)
        #expect(timerProvider.createdTimers.first?.isResumed == true)
    }

    @Test
    func didEnterBackgroundNotification_stopsTimer() async throws {
        // Given
        await sut.start()
        let timer = try #require(timerProvider.createdTimers.first)
        #expect(timer.isResumed == true)
        #expect(timer.isCancelled == false)

        // When - app enters background
        await withCheckedContinuation { continuation in
            timer.onCancelled = { continuation.resume() }

            notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        }

        // Then - timer should be cancelled
        #expect(timer.isCancelled == true)

        // When - app becomes active again, wait for new timer to be resumed
        await withCheckedContinuation { continuation in
            timerProvider.onTimerCreated = { $0.onResume = { continuation.resume() } }

            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        // Then - new timer should be created
        #expect(timerProvider.createdTimers.count == 2)
        #expect(timerProvider.createdTimers.last?.isResumed == true)
    }
}

// MARK: - Mock Timer

private final class MockDispatchTimer: DispatchTimerProtocol {
    private(set) var isResumed = false
    private(set) var isCancelled = false
    var onCancelled: () -> Void = { }
    var onResume: () -> Void = { }
    private var eventHandler: (() -> Void)?

    func schedule(deadline: DispatchTime, repeating: Double, leeway: DispatchTimeInterval) {
        // Not used in tests
    }

    func setEventHandler(handler: (() -> Void)?) {
        eventHandler = handler
    }

    func resume() {
        isResumed = true
        onResume()
    }

    func cancel() {
        isCancelled = true
        onCancelled()
    }

    /// Test helper to manually fire the timer
    func fire() {
        eventHandler?()
    }
}

private final class MockDispatchTimerProvider: DispatchTimerProviding {
    private(set) var createdTimers: [MockDispatchTimer] = []
    var onTimerCreated: (MockDispatchTimer) -> Void = { _ in }

    func makeTimer(queue: DispatchQueue) -> DispatchTimerProtocol {
        let timer = MockDispatchTimer()
        createdTimers.append(timer)
        onTimerCreated(timer)
        return timer
    }
}

// MARK: - Mock Store Provider

private final class MockPOSCatalogStoreProvider: POSCatalogStoreProviding {
    var defaultStoreID: Int64?
    var posCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?
}

// MARK: - Mock Coordinator

private final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performSmartSyncInvocationCount = 0
    var performSmartSyncSiteID: Int64?
    var performSmartSyncResult: Result<Void, Error> = .success(())
    var onPerformSmartSyncCalled: (() -> Void)?

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval, isBackgroundSync: Bool) async throws {
        performSmartSyncInvocationCount += 1
        performSmartSyncSiteID = siteID
        onPerformSmartSyncCalled?()

        switch performSmartSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool, isBackgroundSync: Bool) async throws {
        // Not used
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        // Not used
    }

    let fullSyncStateModel = POSCatalogSyncStateModel()

    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        return await fullSyncStateModel.state[siteID] ?? .syncNeverDone(siteID: siteID)
    }

    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        return false
    }

    func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        return nil
    }

    func stopOngoingSyncs(for siteID: Int64) async {}

    func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws {
        // Not used in these tests
    }

    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        // no-op
    }

    func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async {
        // no-op
    }
}
