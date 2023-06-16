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

    func test_tracker_triggers_expected_analytics_event_after_all_actions_end() {
        // Given
        tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)

        // When only one action is ended
        tracker.end(action: .syncDashboardStats)
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 0)

        // When all actions are ended
        tracker.end(action: .loadOnboardingTasks)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue))
    }

    func test_ending_action_again_after_all_actions_are_ended_does_not_trigger_analytics_event_again() {
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

    func completeAllStartupActions() {
        AppStartupWaitingTimeTracker.StartupAction.allCases.forEach { action in
            tracker.end(action: action)
        }
    }
}
