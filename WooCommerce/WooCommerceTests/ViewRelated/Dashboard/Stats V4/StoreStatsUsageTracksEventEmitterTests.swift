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

    func test_it_will_emit_an_event_when_the_time_and_interaction_thresholds_are_reached() throws {
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
        assertEqual(try XCTUnwrap(analyticsProvider.receivedEvents.first), "used_analytics")
    }

    func test_it_will_not_emit_an_event_if_the_interaction_threshold_is_not_reached() {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
        ])

        // When
        interacted(at: "2021-11-23T00:00:11Z")

        // Then
        assertEmpty(analyticsProvider.receivedEvents)
    }

    func test_it_will_not_emit_an_event_if_the_time_threshold_is_not_reached() {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:03Z",
        ])

        // When
        interacted(at: "2021-11-23T00:00:04Z")

        // Then
        assertEmpty(analyticsProvider.receivedEvents)
    }

    func test_it_will_not_emit_an_event_when_the_user_idled() {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:04Z",
        ])

        // When
        // 10 seconds after the last one
        interacted(at: "2021-11-23T00:00:14Z")

        // Then
        assertEmpty(analyticsProvider.receivedEvents)
    }

    func test_it_can_still_emit_an_event_later_after_idling() {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:04Z",
            "2021-11-23T00:00:14Z", // idled
        ])

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        interacted(at: [
            "2021-11-23T00:01:00Z",
            "2021-11-23T00:01:01Z",
            "2021-11-23T00:01:02Z",
            "2021-11-23T00:01:04Z",
            "2021-11-23T00:01:10Z",
        ])

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
    }

    func test_it_will_not_emit_an_event_right_away_after_an_event_was_previously_emitted() throws {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:01Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:10Z",
            "2021-11-23T00:00:11Z", // event triggered here
        ])

        assertNotEmpty(analyticsProvider.receivedEvents)

        // When
        interacted(at: "2021-11-23T00:00:12Z")

        // Then
        assertEqual(analyticsProvider.receivedEvents.count, 1)
    }

    func test_it_will_emit_another_event_if_the_threshold_is_reached_again() throws {
        // Given
        interacted(at: [
            "2021-11-23T00:00:00Z",
            "2021-11-23T00:00:02Z",
            "2021-11-23T00:00:04Z",
            "2021-11-23T00:00:06Z",
            "2021-11-23T00:00:10Z", // event triggered here
            "2021-11-23T00:00:12Z",
            "2021-11-23T00:00:14Z",
            "2021-11-23T00:00:16Z",
            "2021-11-23T00:00:18Z",
        ])

        // Only 1 event because the second set of interactions have not reached the threshold yet
        assertEqual(analyticsProvider.receivedEvents.count, 1)

        // When
        interacted(at: "2021-11-23T00:00:22Z")

        // Then
        assertEqual(analyticsProvider.receivedEvents.count, 2)
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
