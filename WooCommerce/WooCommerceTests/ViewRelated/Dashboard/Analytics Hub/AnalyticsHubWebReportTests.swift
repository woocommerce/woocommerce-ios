import XCTest
import TestKit
@testable import WooCommerce

final class AnalyticsHubWebReportTests: XCTestCase {

    let exampleAdminURL = "https://example.com/wp-admin/"
    let exampleDefaultReport = "admin.php?page=wc-admin&path=%2Fanalytics%2Frevenue"

    func test_getUrl_returns_expected_default_revenue_report_url() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: nil, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + "admin.php?page=wc-admin&path=%2Fanalytics%2Frevenue")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_default_orders_report_url() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .orders, timeRange: nil, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + "admin.php?page=wc-admin&path=%2Fanalytics%2Forders")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_default_products_report_url() {
        // Given
        let reportURL = AnalyticsHubWebReport.getUrl(for: .products, timeRange: nil, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + "admin.php?page=wc-admin&path=%2Fanalytics%2Fproducts")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_with_custom_time_range() throws {
        // Given
        let start = try XCTUnwrap(Date.dateWithISO8601String("2024-01-01T00:00:00Z"))
        let end = try XCTUnwrap(Date.dateWithISO8601String("2024-01-07T00:00:00Z"))
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .custom(start: start, end: end)
        let timeZone = TimeZone(abbreviation: "GMT") ?? TimeZone.current

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL, timeZone: timeZone)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=custom&after=2024-01-01&before=2024-01-07&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_today_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .today

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=today&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_yesterday_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yesterday

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=yesterday&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_last_week_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastWeek

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=last_week&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_last_month_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastMonth

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=last_month&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_last_quarter_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastQuarter

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=last_quarter&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_last_year_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastYear

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=last_year&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_week_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .weekToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=week&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_month_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .monthToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=month&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_quarter_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .quarterToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=quarter&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

    func test_getUrl_returns_expected_URL_for_year_to_date_time_range() {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yearToDate

        // When
        let reportURL = AnalyticsHubWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let expectedURL = URL(string: exampleAdminURL + exampleDefaultReport + "&period=year&compare=previous_period")
        assertEqual(expectedURL, reportURL)
    }

}
