import Testing
import Foundation
import Yosemite
@testable import WooCommerce

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
        sut.start()

        // Then
        #expect(timerProvider.createdTimers.count == 1)
        #expect(timerProvider.createdTimers.first?.isResumed == true)
    }

    @Test
    func start_whenFeatureFlagDisabled_doesNotCreateTimer() async throws {
        // Given
        let disabledFlags = MockFeatureFlagService()
        disabledFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleLocalCatalogi1] = false
        let dispatcher = ForegroundPOSCatalogSyncDispatcher(
            notificationCenter: notificationCenter,
            timerProvider: timerProvider,
            featureFlagService: disabledFlags,
            stores: stores,
            isAppActive: { true }
        )

        // When
        dispatcher.start()

        // Then
        #expect(timerProvider.createdTimers.isEmpty)
    }

    @Test
    func timerFires_whenRequirementsMet_triggersSync() async throws {
        // Given
        let coordinator = MockPOSCatalogSyncCoordinator()
        stores.testPOSCatalogSyncCoordinator = coordinator

        sut.start()
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
        let noStoreSession = SessionManager.testingInstance
        noStoreSession.setStoreId(nil)
        let noStoreStores = MockStoresManager(sessionManager: noStoreSession)
        noStoreStores.testPOSCatalogSyncCoordinator = coordinator
        let dispatcher = ForegroundPOSCatalogSyncDispatcher(
            notificationCenter: notificationCenter,
            timerProvider: timerProvider,
            featureFlagService: featureFlags,
            stores: noStoreStores,
            isAppActive: { true }
        )

        dispatcher.start()
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

        sut.start()
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
        sut.start()
        let firstTimer = try #require(timerProvider.createdTimers.first)
        #expect(timerProvider.createdTimers.count == 1)

        // When - change site to 456 and start again
        sessionManager.setStoreId(456)
        sut.start()

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
        sut.start()
        let timer = try #require(timerProvider.createdTimers.first)
        #expect(timer.isResumed == true)

        // When - default site changes
        notificationCenter.post(name: .StoresManagerDidUpdateDefaultSite, object: nil)

        // Then - dispatcher stops
        #expect(timer.isCancelled == true)

        // Verify dispatcher can restart after notification
        sut.start()
        #expect(timerProvider.createdTimers.count == 2)
        #expect(timerProvider.createdTimers.last?.isResumed == true)
    }
}

// MARK: - Mock Timer

private final class MockDispatchTimer: DispatchTimerProtocol {
    private(set) var isResumed = false
    private(set) var isCancelled = false
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
    }

    /// Test helper to manually fire the timer
    func fire() {
        eventHandler?()
    }
}

private final class MockDispatchTimerProvider: DispatchTimerProviding {
    private(set) var createdTimers: [MockDispatchTimer] = []

    func makeTimer(queue: DispatchQueue) -> DispatchTimerProtocol {
        let timer = MockDispatchTimer()
        createdTimers.append(timer)
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
