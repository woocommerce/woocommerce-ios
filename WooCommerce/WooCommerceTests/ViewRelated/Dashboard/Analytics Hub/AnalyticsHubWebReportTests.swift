import XCTest
import TestKit
@testable import WooCommerce

final class AnalyticsHubWebReportTests: XCTestCase {

    let exampleAdminURL = "https://example.com/wp-admin/"

    func test_getURL_returns_expected_absolute_URL_string() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: .today, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = exampleAdminURL + "admin.php?page=wc-admin&path=%2Fanalytics%2Frevenue&period=today&compare=previous_period"
        assertEqual(expectedURL, try XCTUnwrap(reportURL).absoluteString)
    }

    func test_getUrl_returns_URL_containing_expected_revenue_report_path() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: .today, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&path=%2Fanalytics%2Frevenue"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_orders_report_path() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .orders, timeRange: .today, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&path=%2Fanalytics%2Forders"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_products_report_path() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .products, timeRange: .today, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&path=%2Fanalytics%2Fproducts"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_custom_time_range() throws {
        // Given
        let start = try XCTUnwrap(Date.dateWithISO8601String("2024-01-01T00:00:00Z"))
        let end = try XCTUnwrap(Date.dateWithISO8601String("2024-01-07T00:00:00Z"))
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .custom(start: start, end: end)
        let timeZone = TimeZone(abbreviation: "GMT") ?? TimeZone.current

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL, timeZone: timeZone)

        // Then
        let expectedURLString = "&period=custom&after=2024-01-01&before=2024-01-07&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_today_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .today

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=today&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_yesterday_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yesterday

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=yesterday&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_last_week_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastWeek

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=last_week&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_last_month_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastMonth

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=last_month&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_last_quarter_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastQuarter

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=last_quarter&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_last_year_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastYear

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=last_year&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_week_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .weekToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=week&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_month_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .monthToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=month&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_quarter_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .quarterToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=quarter&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_year_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yearToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURLString = "&period=year&compare=previous_period"
        XCTAssertTrue(try XCTUnwrap(reportURL).absoluteString.contains(expectedURLString))
    }

}
