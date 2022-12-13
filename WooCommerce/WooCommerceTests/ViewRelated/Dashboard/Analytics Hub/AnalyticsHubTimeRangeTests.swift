import XCTest
@testable import WooCommerce

final class AnalyticsHubTimeRangeTests: XCTestCase {
    private var testTimezone: TimeZone = {
        TimeZone(abbreviation: "UTC") ?? TimeZone.current
    }()

    private var testCalendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(abbreviation: "UTC") ?? TimeZone.current
        return calendar
    }()

    func test_when_time_range_format_is_simplified_then_describes_only_first_date() {
        // Given
        let startDate = startDate(from: "2022-07-01")!
        let endDate = endDate(from: "2022-07-02")!
        let timeRange = AnalyticsHubTimeRange(start: startDate, end: endDate)

        // When
        let description = timeRange.formatToString(simplified: true, timezone: testTimezone, calendar: testCalendar)

        //Then
        XCTAssertEqual(description, "Jul 1, 2022")
    }

    func test_when_time_range_format_is_in_different_months_then_describes_both_dates() {
        // Given
        let startDate = startDate(from: "2022-07-01")!
        let endDate = endDate(from: "2022-08-02")!
        let timeRange = AnalyticsHubTimeRange(start: startDate, end: endDate)

        // When
        let description = timeRange.formatToString(simplified: false, timezone: testTimezone, calendar: testCalendar)

        //Then
        XCTAssertEqual(description, "Jul 1 - Aug 2, 2022")
    }

    func test_when_time_range_is_in_the_same_month_then_describe_month_only_in_the_start_date() {
        // Given
        let startDate = startDate(from: "2022-07-01")!
        let endDate = endDate(from: "2022-07-05")!
        let timeRange = AnalyticsHubTimeRange(start: startDate, end: endDate)

        // When
        let description = timeRange.formatToString(simplified: false, timezone: testTimezone, calendar: testCalendar)

        //Then
        XCTAssertEqual(description, "Jul 1 - 5, 2022")
    }

    func test_when_time_range_is_in_different_years_then_fully_describe_both_dates() {
        // Given
        let startDate = startDate(from: "2021-04-01")!
        let endDate = endDate(from: "2022-07-15")!
        let timeRange = AnalyticsHubTimeRange(start: startDate, end: endDate)

        // When
        let description = timeRange.formatToString(simplified: false, timezone: testTimezone, calendar: testCalendar)

        //Then
        XCTAssertEqual(description, "Apr 1, 2021 - Jul 15, 2022")
    }
    
    //TODO different years same month

    private func startDate(from date: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = testTimezone
        return dateFormatter.date(from: date)?.startOfDay(timezone: testTimezone)
    }

    private func endDate(from date: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = testTimezone
        return dateFormatter.date(from: date)?.endOfDay(timezone: testTimezone)
    }
}
