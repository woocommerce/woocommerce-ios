import XCTest
@testable import WooCommerce

final class AnalyticsHubTimeRangeTests: XCTestCase {
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    func test_when_time_range_inits_with_thisYear_then_generate_expected_ranges() {
        // Given
        let currentDate = dateFrom("2020-02-29")
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisYear, currentDate: currentDate)

        // When
        let currentTimeRange = timeRange.currentTimeRange
        let previousTimeRange = timeRange.previousTimeRange

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2020-01-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2020-02-29"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2019-01-01"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2019-02-28"))
    }

    func test_when_time_range_inits_with_thisMonth_then_generate_expected_ranges() {
        // Given
        let currentDate = dateFrom("2010-07-31")
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisMonth, currentDate: currentDate)

        // When
        let currentTimeRange = timeRange.currentTimeRange
        let previousTimeRange = timeRange.previousTimeRange

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2010-07-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2010-07-31"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2010-06-01"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2010-06-30"))
    }

    private func dateFrom(_ date: String) -> Date {
        return dateFormatter.date(from: date)!
    }
}
