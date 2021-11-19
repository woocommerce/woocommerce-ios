import XCTest
@testable import WooCommerce
@testable import Yosemite

final class OrderDateRangeFilterTests: XCTestCase {
    func test_computedStartDate_with_any_filter_will_return_expected_data() {
        // Given
        let filters = OrderDateRangeFilter(filter: .any, startDate: nil, endDate: nil)

        // Then
        XCTAssertEqual(filters.computedStartDate, nil)
        XCTAssertEqual(filters.computedEndDate, nil)
    }

    func test_computedStartDate_with_today_filter_will_return_expected_data() {
        // Given
        let filters = OrderDateRangeFilter(filter: .today, startDate: nil, endDate: nil)

        // Then
        XCTAssertEqual(filters.computedStartDate, Date().startOfDay(timezone: TimeZone.siteTimezone))
        XCTAssertEqual(filters.computedEndDate, nil)
    }

    func test_computedStartDate_with_last2Days_filter_will_return_expected_data() {
        // Given
        let filters = OrderDateRangeFilter(filter: .last2Days, startDate: nil, endDate: nil)

        // Then
        XCTAssertEqual(filters.computedStartDate, Calendar.current.date(byAdding: .day, value: -2, to: Date())?.startOfDay(timezone: TimeZone.siteTimezone))
        XCTAssertEqual(filters.computedEndDate, nil)
    }

    func test_computedStartDate_with_last7Days_filter_will_return_expected_data() {
        // Given
        let filters = OrderDateRangeFilter(filter: .last7Days, startDate: nil, endDate: nil)

        // Then
        XCTAssertEqual(filters.computedStartDate, Calendar.current.date(byAdding: .day, value: -7, to: Date())?.startOfDay(timezone: TimeZone.siteTimezone))
        XCTAssertEqual(filters.computedEndDate, nil)
    }

    func test_computedStartDate_with_last30Days_filter_will_return_expected_data() {
        // Given
        let filters = OrderDateRangeFilter(filter: .last30Days, startDate: nil, endDate: nil)

        // Then
        XCTAssertEqual(filters.computedStartDate, Calendar.current.date(byAdding: .day, value: -30, to: Date())?.startOfDay(timezone: TimeZone.siteTimezone))
        XCTAssertEqual(filters.computedEndDate, nil)
    }

    func test_computedStartDate_with_custom_filter_will_return_expected_data() {
        // Given
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        let filters = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)

        // Then
        XCTAssertEqual(filters.computedStartDate, startDate?.startOfDay(timezone: TimeZone.siteTimezone))
        XCTAssertEqual(filters.computedEndDate, endDate?.endOfDay(timezone: TimeZone.siteTimezone))
    }
}
