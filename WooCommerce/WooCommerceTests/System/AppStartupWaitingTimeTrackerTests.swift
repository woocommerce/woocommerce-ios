import XCTest
@testable import WooCommerce

final class AppStartupWaitingTimeTrackerTests: XCTestCase {
    private var notificationCenter: NotificationCenter!
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var tracker: AppStartupWaitingTimeTracker!

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        sessionManager = nil
        stores = nil
        analyticsProvider = nil
        notificationCenter = nil
        tracker = nil

        super.tearDown()
    }

    func test_tracker_does_not_trigger_analytics_stat_while_logged_out() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: false)
        let stores = MockStoresManager(sessionManager: sessionManager)
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .launchApp)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_triggers_expected_analytics_stat_while_logged_in_with_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .launchApp)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_triggers_expected_analytics_stat_while_logged_in_without_wpcom() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true, isWPCom: false)
        let stores = MockStoresManager(sessionManager: sessionManager)
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .launchApp)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_only_ends_when_all_pending_actions_are_completed() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When some actions are completed
        AppStartupWaitingTimeTracker.notify(action: .launchApp, withStatus: .started, notificationCenter: notificationCenter)
        AppStartupWaitingTimeTracker.notify(action: .validateRoleEligibility, withStatus: .started, notificationCenter: notificationCenter)
        AppStartupWaitingTimeTracker.notify(action: .launchApp, withStatus: .completed, notificationCenter: notificationCenter)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))

        // When all actions are completed
        AppStartupWaitingTimeTracker.notify(action: .validateRoleEligibility, withStatus: .completed, notificationCenter: notificationCenter)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_validateRoleEligibility_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .validateRoleEligibility)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_checkFeatureAnnouncements_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .checkFeatureAnnouncements)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_restoreSessionSite_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .restoreSessionSite)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_synchronizeEntities_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .synchronizeEntities)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_checkMinimumWooVersion_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .checkMinimumWooVersion)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_syncDashboardStats_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .syncDashboardStats)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_syncTopPerformers_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .syncTopPerformers)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_fetchExperimentAssignments_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .fetchExperimentAssignments)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_syncJITMs_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .syncJITMs)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_observes_syncPaymentConnectionTokens_startup_action() {
        // Given
        tracker = AppStartupWaitingTimeTracker(notificationCenter: notificationCenter, stores: stores, analyticsService: analytics)

        // When
        triggerNotifications(for: .syncPaymentConnectionTokens)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }
}

private extension AppStartupWaitingTimeTrackerTests {
    /// Triggers expected notifications for provided action.
    ///
    func triggerNotifications(for action: NSNotification.Name) {
        AppStartupWaitingTimeTracker.notify(action: action, withStatus: .started, notificationCenter: notificationCenter)
        AppStartupWaitingTimeTracker.notify(action: action, withStatus: .completed, notificationCenter: notificationCenter)
    }
}
