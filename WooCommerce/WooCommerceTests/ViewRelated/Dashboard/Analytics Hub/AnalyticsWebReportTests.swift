import XCTest
import TestKit
@testable import WooCommerce

final class AnalyticsWebReportTests: XCTestCase {

    let exampleAdminURL = "https://example.com/wp-admin/"

    func test_getURL_returns_expected_report_URL() throws {
        // Given
        let reportURL = try XCTUnwrap(AnalyticsWebReport.getUrl(for: .revenue, timeRange: .today, storeAdminURL: exampleAdminURL))

        // Then
        let expectedURL = try XCTUnwrap(URL(string: exampleAdminURL +
                                            "admin.php?page=wc-admin&path=%2Fanalytics%2Frevenue&period=today&compare=previous_period"))

        let expectedComponents = URLComponents(url: expectedURL, resolvingAgainstBaseURL: false)
        let reportComponents = URLComponents(url: reportURL, resolvingAgainstBaseURL: false)

        let expectedQueryItems = Set(try XCTUnwrap(expectedComponents?.queryItems))
        let reportQueryItems = Set(try XCTUnwrap(reportComponents?.queryItems))

        assertEqual(expectedComponents?.scheme, reportComponents?.scheme)
        assertEqual(expectedComponents?.host, reportComponents?.host)
        assertEqual(expectedComponents?.path, reportComponents?.path)
        assertEqual(expectedQueryItems, reportQueryItems)
    }

    func test_getUrl_returns_URL_containing_expected_revenue_report_path() throws {
        // Given
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: .today, storeAdminURL: exampleAdminURL)

        // When
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems

        // Then
        let expectedQueryItem = URLQueryItem(name: "path", value: "/analytics/revenue")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_orders_report_path() throws {
        // Given
        let reportURL = AnalyticsWebReport.getUrl(for: .orders, timeRange: .today, storeAdminURL: exampleAdminURL)

        // When
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems

        // Then
        let expectedQueryItem = URLQueryItem(name: "path", value: "/analytics/orders")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_products_report_path() throws {
        // Given
        let reportURL = AnalyticsWebReport.getUrl(for: .products, timeRange: .today, storeAdminURL: exampleAdminURL)

        // When
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems

        // Then
        let expectedQueryItem = URLQueryItem(name: "path", value: "/analytics/products")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_query_parameters_for_custom_time_range() throws {
        // Given
        let start = try XCTUnwrap(Date.dateWithISO8601String("2024-01-01T00:00:00Z"))
        let end = try XCTUnwrap(Date.dateWithISO8601String("2024-01-07T00:00:00Z"))
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .custom(start: start, end: end)
        let timeZone = TimeZone(abbreviation: "GMT") ?? TimeZone.current

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL, timeZone: timeZone)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItems = [
            URLQueryItem(name: "period", value: "custom"),
            URLQueryItem(name: "after", value: "2024-01-01"),
            URLQueryItem(name: "compare", value: "previous_period")
        ]
        for expectedQueryItem in expectedQueryItems {
            XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
        }
    }

    func test_getUrl_returns_URL_containing_expected_period_for_today_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .today

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "today")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_yesterday_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yesterday

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "yesterday")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_last_week_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastWeek

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "last_week")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_last_month_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastMonth

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "last_month")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_last_quarter_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastQuarter

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "last_quarter")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_last_year_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .lastYear

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "last_year")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_week_to_date_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .weekToDate

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "week")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_month_to_date_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .monthToDate

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "month")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_quarter_to_date_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .quarterToDate

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "quarter")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

    func test_getUrl_returns_URL_containing_expected_period_for_year_to_date_time_range() throws {
        // Given
        let timeRange: AnalyticsHubTimeRangeSelection.SelectionType = .yearToDate

        // When
        let reportURL = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: exampleAdminURL)

        // Then
        let reportQueryItems = URLComponents(url: try XCTUnwrap(reportURL), resolvingAgainstBaseURL: false)?.queryItems
        let expectedQueryItem = URLQueryItem(name: "period", value: "year")
        XCTAssertTrue(try XCTUnwrap(reportQueryItems).contains(expectedQueryItem))
    }

}
