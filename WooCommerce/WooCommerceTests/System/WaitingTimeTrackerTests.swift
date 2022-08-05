import XCTest
@testable import WooCommerce

/// WaitingTimeTracker Unit Tests
///
class WaitingTimeTrackerTests: XCTestCase {
    private var testAnalytics = TestAnalytics()

    func testTimeElapsedEvaluationIsCorrect() {
        var currentTimeCallCounter = 0.0

        // Given
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails,
                                                analyticsService: testAnalytics
        ) {
            currentTimeCallCounter += 1
            return currentTimeCallCounter * 1000
        }

        // When
        waitingTracker.end()

        // Then
        XCTAssertNotNil(testAnalytics.lastReceivedEvent)
    }

    class TestAnalytics: Analytics {
        var lastReceivedEvent: WooAnalyticsStat? = nil

        func track(_ stat: WooAnalyticsStat, properties: [AnyHashable: Any]?, error: Error?) {
            lastReceivedEvent = stat
        }

        // Protocol conformance code

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
        }

        var userHasOptedIn: Bool = false
        private(set) var analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()
    }
}
