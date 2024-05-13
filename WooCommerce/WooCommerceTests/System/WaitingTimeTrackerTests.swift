import XCTest
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
@testable import WooCommerce

/// WaitingTimeTracker Unit Tests
///
class WaitingTimeTrackerTests: XCTestCase {
    private var testAnalytics = TestAnalytics()

    func testTimeElapsedEvaluationIsCorrect() {
        var currentTimeCallCounter = 0.0

        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails, analyticsService: testAnalytics) {
            currentTimeCallCounter += 1
            return currentTimeCallCounter * 10
        }

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedWaitingTime, 10.0)
    }

    func testOrderDetailsTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails, analyticsService: testAnalytics, currentTimeInMillis: { 0 })

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedEventName, WooAnalyticsStat.orderDetailWaitingTimeLoaded.rawValue)
    }

    func testTopPerformersTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers,
                                                analyticsService: testAnalytics,
                                                currentTimeInMillis: { 0 }
        )

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedEventName, WooAnalyticsStat.dashboardTopPerformersWaitingTimeLoaded.rawValue)
    }

    func testMainStatsTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats,
                                                analyticsService: testAnalytics,
                                                currentTimeInMillis: { 0 }
        )

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedEventName, WooAnalyticsStat.dashboardMainStatsWaitingTimeLoaded.rawValue)
    }

    func test_analytics_hub_track_scenario_triggers_expected_analytics_stat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .analyticsHub,
                                                analyticsService: testAnalytics,
                                                currentTimeInMillis: { 0 }
        )

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedEventName, WooAnalyticsStat.analyticsHubWaitingTimeLoaded.rawValue)
    }

    func test_appStartup_track_scenario_triggers_expected_analytics_stat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .appStartup,
                                                analyticsService: testAnalytics,
                                                currentTimeInMillis: { 0 }
        )

        // When
        waitingTracker.end()

        // Then
        XCTAssertEqual(testAnalytics.lastReceivedEventName, WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue)
    }

    class TestAnalytics: Analytics {
        var lastReceivedEventName: String? = nil
        var lastReceivedWaitingTime: TimeInterval? = nil

        // MARK: - Protocol conformance

        func initialize() {
        }

        func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
            lastReceivedEventName = eventName
            lastReceivedWaitingTime = properties?["waiting_time"] as? TimeInterval
        }

        func refreshUserData() {
        }

        func setUserHasOptedOut(_ optedOut: Bool) {
            userHasOptedIn = !optedOut
        }

        var userHasOptedIn: Bool = true
        private(set) var analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()
    }
}
