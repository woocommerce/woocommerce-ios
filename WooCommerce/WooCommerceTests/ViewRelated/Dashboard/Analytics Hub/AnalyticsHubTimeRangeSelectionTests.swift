import XCTest
@testable import WooCommerce

final class AnalyticsHubTimeRangeSelectionTests: XCTestCase {
    private var testTimezone: TimeZone = {
        TimeZone(abbreviation: "UTC") ?? TimeZone.current
    }()

    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC") ?? TimeZone.current
        return dateFormatter
    }()

    func test_when_time_range_inits_with_yearToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2020-02-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yearToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2020-01-01"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2020-02-29"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2019-01-01"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2019-02-28"))
    }

    func test_when_time_range_inits_with_monthToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2010-07-31")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .monthToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2010-07-01"))
        XCTAssertEqual(currentTimeRange.end, startDate(from: "2010-07-31"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2010-06-01"))
        XCTAssertEqual(previousTimeRange.end, startDate(from: "2010-06-30"))
    }

    func test_when_time_range_inits_with_weekToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .weekToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-06-27"))
        XCTAssertEqual(currentTimeRange.end, startDate(from: "2022-07-01"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-20"))
        XCTAssertEqual(previousTimeRange.end, startDate(from: "2022-06-24"))
    }

    func test_when_time_range_inits_with_today_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .today,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-07-01"))
        XCTAssertEqual(currentTimeRange.end, startDate(from: "2022-07-01"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-30"))
        XCTAssertEqual(previousTimeRange.end, startDate(from: "2022-06-30"))
    }

    func test_when_time_range_inits_with_yesterday_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yesterday,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-06-30"))
        XCTAssertEqual(currentTimeRange.end, endDate(from: "2022-06-30"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-29"))
        XCTAssertEqual(previousTimeRange.end, endDate(from: "2022-06-29"))
    }

    func test_when_time_range_inits_with_yearToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yearToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jan 1 - Jul 1, 2021")
    }

    func test_when_time_range_inits_with_monthToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-31")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .monthToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1 - 31, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 1 - 30, 2022")
    }

    func test_when_time_range_inits_with_weekToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .weekToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 25 - 29, 2022")
        XCTAssertEqual(previousRangeDescription, "Jul 18 - 22, 2022")
    }

    func test_when_time_range_inits_with_weekToDate_with_different_months_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-02")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .weekToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jun 27 - Jul 2, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 20 - 25, 2022")
    }

    func test_when_time_range_inits_with_today_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .today,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 30, 2022")
    }

    func test_when_time_range_inits_with_yesterday_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate((from: "2022-07-02")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yesterday,
                                                       currentDate: today,
                                                       timezone: testTimezone)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 30, 2022")
    }

    private func currentDate(from date: String) -> Date {
        return dateFormatter.date(from: date)!
    }

    private func startDate(from date: String) -> Date? {
        return dateFormatter.date(from: date)?.startOfDay(timezone: testTimezone)
    }

    private func endDate(from date: String) -> Date? {
        return dateFormatter.date(from: date)?.endOfDay(timezone: testTimezone)
    }
}
