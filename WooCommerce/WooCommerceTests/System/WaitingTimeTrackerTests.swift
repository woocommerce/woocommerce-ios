import XCTest
import enum WooFoundation.WooAnalyticsStat
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
        XCTAssertEqual(testAnalytics.lastReceivedStat, .orderDetailWaitingTimeLoaded)
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
        XCTAssertEqual(testAnalytics.lastReceivedStat, .dashboardTopPerformersWaitingTimeLoaded)
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
        XCTAssertEqual(testAnalytics.lastReceivedStat, .dashboardMainStatsWaitingTimeLoaded)
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
        XCTAssertEqual(testAnalytics.lastReceivedStat, .analyticsHubWaitingTimeLoaded)
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
        XCTAssertEqual(testAnalytics.lastReceivedStat, .applicationOpenedWaitingTimeLoaded)
    }

    class TestAnalytics: Analytics {
        var lastReceivedStat: WooAnalyticsStat? = nil
        var lastReceivedWaitingTime: TimeInterval? = nil

        func track(_ stat: WooAnalyticsStat, properties: [AnyHashable: Any]?, error: Error?) {
            lastReceivedStat = stat
            lastReceivedWaitingTime = properties?["waiting_time"] as? TimeInterval
        }

        // MARK: - Protocol conformance

        func initialize() {
        }

        func track(_ stat: WooAnalyticsStat) {
        }

        func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        }

        func track(_ stat: WooAnalyticsStat, withError error: Error) {
        }

        func refreshUserData() {
        }

        func setUserHasOptedOut(_ optedOut: Bool) {
            userHasOptedIn = !optedOut
        }

        var userHasOptedIn: Bool = false
        private(set) var analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()
    }
}
