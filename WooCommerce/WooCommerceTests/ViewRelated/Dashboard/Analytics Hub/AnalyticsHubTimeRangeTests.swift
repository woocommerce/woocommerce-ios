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
        let currentDate = dateFrom("2022-02-05")
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisYear, currentDate: currentDate)

        // When
        let currentTimeRange = timeRange.currentTimeRange
        let previousTimeRange = timeRange.previousTimeRange

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2022-01-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2022-02-05"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2021-01-01"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2021-02-05"))
    }

    private func dateFrom(_ date: String) -> Date {
        return dateFormatter.date(from: date)!
    }
}
