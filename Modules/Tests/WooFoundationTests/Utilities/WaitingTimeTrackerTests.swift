import XCTest
@testable import WooFoundation

/// WaitingTimeTracker Unit Tests
///
final class WaitingTimeTrackerTests: XCTestCase {
    func testTimeElapsedEvaluationIsCorrect() {
        var currentTimeCallCounter = 0.0

        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails) {
            currentTimeCallCounter += 1
            return currentTimeCallCounter * 10
        }

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.properties["waiting_time"] as? TimeInterval, 10.0)
    }

    func testOrderDetailsTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails, currentTimestampSeconds: { 0 })

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.orderDetailWaitingTimeLoaded.rawValue)
    }

    func testTopPerformersTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers,
                                                currentTimestampSeconds: { 0 }
        )

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.dashboardTopPerformersWaitingTimeLoaded.rawValue)
    }

    func testMainStatsTrackScenarioTriggersExpectedAnalyticsStat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats,
                                                currentTimestampSeconds: { 0 }
        )

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.dashboardMainStatsWaitingTimeLoaded.rawValue)
    }

    func test_analytics_hub_track_scenario_triggers_expected_analytics_stat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .analyticsHub,
                                                currentTimestampSeconds: { 0 }
        )

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.analyticsHubWaitingTimeLoaded.rawValue)
    }

    func test_appStartup_track_scenario_triggers_expected_analytics_stat() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .appStartup,
                                                currentTimestampSeconds: { 0 }
        )

        // When
        let event = waitingTracker.end()

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.applicationOpenedWaitingTimeLoaded.rawValue)
    }

    func test_timeElapsed_evaluation_in_milliseconds_is_correct() {
        // Given
        var currentTimeCallCounter = 0.0
        let expectedReceivedWaitingTime = 10_000.0 // 10s * 1000 ms
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails) {
            currentTimeCallCounter += 1
            return currentTimeCallCounter * 10
        }

        // When
        let event = waitingTracker.end(using: .milliseconds)

        // Then
        XCTAssertEqual(event.properties["waiting_time"] as? TimeInterval, expectedReceivedWaitingTime)
    }

    func test_track_scenario_triggers_expected_analytics_stat_in_milliseconds() {
        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .pointOfSaleLoaded,
                                                currentTimestampSeconds: { 0 })

        // When
        let event = waitingTracker.end(using: .milliseconds)

        // Then
        XCTAssertEqual(event.statName.rawValue, WooAnalyticsStat.pointOfSaleLoaded.rawValue)
    }
}
