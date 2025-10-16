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
    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let sut: ForegroundPOSCatalogSyncDispatcher

    init() {
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleLocalCatalogi1] = true
        sessionManager = SessionManager.testingInstance
        sessionManager.setStoreId(123)
        stores = MockStoresManager(sessionManager: sessionManager)
        sut = ForegroundPOSCatalogSyncDispatcher(
            notificationCenter: notificationCenter,
            timerProvider: timerProvider,
            featureFlagService: featureFlags,
            stores: stores,
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
        let coordinator = MockPOSCatalogSyncCoordinator()
        stores.testPOSCatalogSyncCoordinator = coordinator

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
        let coordinator = MockPOSCatalogSyncCoordinator()
        sessionManager.setStoreId(nil)
        stores.testPOSCatalogSyncCoordinator = coordinator

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
        let coordinator = MockPOSCatalogSyncCoordinator()
        coordinator.performSmartSyncResult = .failure(POSCatalogSyncError.syncAlreadyInProgress(siteID: 123))
        stores.testPOSCatalogSyncCoordinator = coordinator

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
        sessionManager.setStoreId(456)
        await sut.start()

        // Then - old timer cancelled, new timer created
        #expect(firstTimer.isCancelled == true)
        #expect(timerProvider.createdTimers.count == 2)
        #expect(timerProvider.createdTimers.last?.isResumed == true)

        // Verify sync uses new site ID
        let coordinator = MockPOSCatalogSyncCoordinator()
        stores.testPOSCatalogSyncCoordinator = coordinator
        let newTimer = try #require(timerProvider.createdTimers.last)

        await withCheckedContinuation { continuation in
            coordinator.onPerformSmartSyncCalled = {
                continuation.resume()
            }
            newTimer.fire()
        }

        #expect(coordinator.performSmartSyncSiteID == 456)
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
            stores: stores,
            isAppActive: { false }
        )
        await inactiveDispatcher.start()

        // Then - no timer created yet
        #expect(timerProvider.createdTimers.isEmpty)

        // When - app becomes active, wait for timer to be created
        await withCheckedContinuation { continuation in
            timerProvider.onTimerCreated = { continuation.resume() }

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

        // When - app becomes active again, wait for new timer
        await withCheckedContinuation { continuation in
            timerProvider.onTimerCreated = { continuation.resume() }

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
    private var eventHandler: (() -> Void)?

    func schedule(deadline: DispatchTime, repeating: Double, leeway: DispatchTimeInterval) {
        // Not used in tests
    }

    func setEventHandler(handler: (() -> Void)?) {
        eventHandler = handler
    }

    func resume() {
        isResumed = true
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
    var onTimerCreated: () -> Void = { }

    func makeTimer(queue: DispatchQueue) -> DispatchTimerProtocol {
        let timer = MockDispatchTimer()
        createdTimers.append(timer)
        onTimerCreated()
        return timer
    }
}

// MARK: - Mock Coordinator

private final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performSmartSyncInvocationCount = 0
    var performSmartSyncSiteID: Int64?
    var performSmartSyncResult: Result<Void, Error> = .success(())
    var onPerformSmartSyncCalled: (() -> Void)?

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval) async throws {
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

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        // Not used
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        // Not used
    }
}
