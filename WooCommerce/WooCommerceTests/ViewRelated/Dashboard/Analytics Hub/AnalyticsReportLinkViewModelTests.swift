import XCTest
import protocol WooFoundation.Analytics
@testable import WooCommerce

final class AnalyticsReportLinkViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var eventEmitter: StoreStatsUsageTracksEventEmitter!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
    }

    func test_onWebViewOpen_tracks_expected_events() throws {
        // Given
        let vm = AnalyticsReportLinkViewModel(reportType: .revenue,
                                              period: .weekToDate,
                                              webViewTitle: "",
                                              reportURL: try XCTUnwrap(URL(string: "https://woocommerce.com/")),
                                              usageTracksEventEmitter: eventEmitter,
                                              analytics: analytics)

        // When
        vm.onWebViewOpen()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "analytics_hub_view_full_report_tapped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["report"] as? String, "revenue")
        XCTAssertEqual(eventProperties["period"] as? String, "Week to Date")
        XCTAssertEqual(eventProperties["compare"] as? String, "previous_period")
    }

    func test_onWebViewOpen_triggers_used_analytics_event_when_the_time_and_interaction_thresholds_are_reached() throws {
        // Given
        let vm = AnalyticsReportLinkViewModel(reportType: .revenue,
                                              period: .weekToDate,
                                              webViewTitle: "",
                                              reportURL: try XCTUnwrap(URL(string: "https://woocommerce.com/")),
                                              usageTracksEventEmitter: eventEmitter,
                                              analytics: analytics)

        // Some analytics interactions have already been emitted
        let firstInteraction = Date()
        interacted(at: [
            firstInteraction,
            Date(timeInterval: 2, since: firstInteraction),
            Date(timeInterval: 4, since: firstInteraction),
            Date(timeInterval: 8, since: firstInteraction)
        ])
        XCTAssertFalse(try XCTUnwrap(analyticsProvider.receivedEvents.contains("used_analytics")))

        // When
        vm.onWebViewOpen(at: Date(timeInterval: 10, since: firstInteraction))

        // Then
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedEvents.contains("used_analytics")))
    }
}


private extension AnalyticsReportLinkViewModelTests {
    func interacted(at dates: [Date]) {
        dates.forEach {
            eventEmitter.interacted(at: $0)
        }
    }
}
