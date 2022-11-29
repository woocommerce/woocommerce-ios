import XCTest
@testable import WooCommerce

final class AnalyticsHubTimeRangeGeneratorTests: XCTestCase {
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    func test_when_time_range_inits_with_thisYear_then_generate_expected_ranges() throws {
        // Given
        let currentDate = dateFrom("2020-02-29")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisYear, currentDate: currentDate)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2020-01-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2020-02-29"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2019-01-01"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2019-02-28"))
    }

    func test_when_time_range_inits_with_thisMonth_then_generate_expected_ranges() throws {
        // Given
        let currentDate = dateFrom("2010-07-31")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisMonth, currentDate: currentDate)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2010-07-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2010-07-31"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2010-06-01"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2010-06-30"))
    }

    func test_when_time_range_inits_with_thisWeek_then_generate_expected_ranges() throws {
        // Given
        let currentDate = dateFrom("2022-07-01")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisWeek, currentDate: currentDate)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2022-06-27"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2022-07-01"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2022-06-20"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2022-06-24"))
    }

    func test_when_time_range_inits_with_today_then_generate_expected_ranges() throws {
        // Given
        let currentDate = dateFrom("2022-07-01")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .today, currentDate: currentDate)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, dateFrom("2022-07-01"))
        XCTAssertEqual(currentTimeRange.end, dateFrom("2022-07-01"))

        XCTAssertEqual(previousTimeRange.start, dateFrom("2022-06-30"))
        XCTAssertEqual(previousTimeRange.end, dateFrom("2022-06-30"))
    }

    func test_when_time_range_inits_with_thisYear_then_generate_expected_descriptions() throws {
        // Given
        let currentDate = dateFrom("2022-07-01")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisYear, currentDate: currentDate)

        // When
        let currentRangeDescription = timeRange.generateCurrentRangeDescription()
        let previousRangeDescription = timeRange.generatePreviousRangeDescription()

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jan 1 - Jul 1, 2021")
    }

    func test_when_time_range_inits_with_thisMonth_then_generate_expected_descriptions() throws {
        // Given
        let currentDate = dateFrom("2022-07-31")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisMonth, currentDate: currentDate)

        // When
        let currentRangeDescription = timeRange.generateCurrentRangeDescription()
        let previousRangeDescription = timeRange.generatePreviousRangeDescription()

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1 - 31, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 1 - 30, 2022")
    }

    func test_when_time_range_inits_with_thisWeek_then_generate_expected_descriptions() throws {
        // Given
        let currentDate = dateFrom("2022-07-29")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisWeek, currentDate: currentDate)

        // When
        let currentRangeDescription = timeRange.generateCurrentRangeDescription()
        let previousRangeDescription = timeRange.generatePreviousRangeDescription()

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 25 - 29, 2022")
        XCTAssertEqual(previousRangeDescription, "Jul 18 - 22, 2022")
    }

    func test_when_time_range_inits_with_thisWeek_with_different_months_then_generate_expected_descriptions() throws {
        // Given
        let currentDate = dateFrom("2022-07-02")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .thisWeek, currentDate: currentDate)

        // When
        let currentRangeDescription = timeRange.generateCurrentRangeDescription()
        let previousRangeDescription = timeRange.generatePreviousRangeDescription()

        // Then
        XCTAssertEqual(currentRangeDescription, "Jun 27 - Jul 2, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 20 - 25, 2022")
    }

    func test_when_time_range_inits_with_today_then_generate_expected_descriptions() throws {
        // Given
        let currentDate = dateFrom("2022-07-01")
        let timeRange = AnalyticsHubTimeRangeGenerator(selectedTimeRange: .today, currentDate: currentDate)

        // When
        let currentRangeDescription = timeRange.generateCurrentRangeDescription()
        let previousRangeDescription = timeRange.generatePreviousRangeDescription()

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 30, 2022")
    }

    private func dateFrom(_ date: String) -> Date {
        return dateFormatter.date(from: date)!
    }
}
