import XCTest
@testable import WooCommerce

final class AppStartupWaitingTimeTrackerTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var tracker: AppStartupWaitingTimeTracker!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        tracker = nil

        super.tearDown()
    }

    func test_tracker_triggers_expected_analytics_event_after_all_actions_are_complete() {
        // Given
        tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)

        // When only one action is complete
        tracker.end(action: .syncDashboardStats)
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 0)

        // When all actions are complete
        tracker.end(action: .loadOnboardingTasks)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_tracker_does_not_trigger_analytics_event_if_action_has_error() {
        // Given
        tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)

        // When
        completeAllStartupActions(withError: MockError.mockError)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 0)
    }

    func test_tracker_does_not_trigger_analytics_event_again_after_tracker_is_completed() {
        // Given
        tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)

        // When all actions are complete
        completeAllStartupActions()
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)

        // When action is ended again
        tracker.end(action: .syncDashboardStats)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
    }

    func test_tracker_does_not_trigger_analytics_event_after_tracker_is_ended_manually() {
        // Given
        tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)

        // When
        tracker.end()
        completeAllStartupActions()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 0)
    }

}

private extension AppStartupWaitingTimeTrackerTests {
    enum MockError: Error {
        case mockError
    }

    func completeAllStartupActions(withError error: Error? = nil) {
        AppStartupWaitingTimeTracker.StartupAction.allCases.forEach { action in
            tracker.end(action: action, withError: error)
        }
    }
}
