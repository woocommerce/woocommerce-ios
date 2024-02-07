import XCTest
@testable import WooCommerce

final class AnalyticsReportLinkViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    func test_onWebViewOpen_tracks_expected_events() throws {
        // Given
        let vm = AnalyticsReportLinkViewModel(reportType: .revenue,
                                              period: .weekToDate,
                                              webViewTitle: "",
                                              reportURL: try XCTUnwrap(URL(string: "https://woo.com/")),
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

}
