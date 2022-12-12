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
