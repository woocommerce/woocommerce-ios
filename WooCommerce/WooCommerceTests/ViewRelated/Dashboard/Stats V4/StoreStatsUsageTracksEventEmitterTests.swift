import XCTest
import TestKit

@testable import WooCommerce

final class StoreStatsUsageTracksEventEmitterTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var dateFormatter: DateFormatter!
    private var calendar: Calendar!

    private var eventEmitter: StoreStatsUsageTracksEventEmitter!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        dateFormatter = DateFormatter.Defaults.iso8601
        calendar = Calendar(identifier: .gregorian, timeZone: dateFormatter.timeZone)

        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
    }

    override func tearDown() {
        eventEmitter = nil
        calendar = nil
        dateFormatter = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_it_will_emit_an_event_when_the_time_and_interaction_thresholds_are_reached() {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:10Z",
        ])

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        interacted(at: "2021-11-23T00:00:11Z")

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
    }
}

private extension StoreStatsUsageTracksEventEmitterTests {
    func interacted(at dates: [String]) {
        dates.forEach {
            interacted(at: $0)
        }
    }

    func interacted(at date: String) {
        let date = dateFormatter.date(from: date)!
        eventEmitter.interacted(at: date)
    }
}
