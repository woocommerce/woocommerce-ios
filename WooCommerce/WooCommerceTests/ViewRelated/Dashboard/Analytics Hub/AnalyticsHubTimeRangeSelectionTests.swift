import XCTest
@testable import WooCommerce

final class AnalyticsHubTimeRangeSelectionTests: XCTestCase {
    private var testTimezone: TimeZone = {
        TimeZone(abbreviation: "PDT") ?? TimeZone.current
    }()

    private var testCalendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(abbreviation: "PDT") ?? TimeZone.current
        return calendar
    }()

    func test_when_time_range_inits_with_yearToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2020-02-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yearToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2020-01-01"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2020-02-29").endOfYear(timezone: testTimezone))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2019-01-01"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2019-02-28"))
    }

    func test_when_time_range_inits_with_lastYear_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2020-02-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastYear,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2019-01-01"))
        XCTAssertEqual(currentTimeRange.end, endDate(from: "2019-12-31"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2018-01-01"))
        XCTAssertEqual(previousTimeRange.end, endDate(from: "2018-12-31"))
    }

    func test_when_time_range_inits_with_quarterToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-02-15")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .quarterToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-01-01"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2022-02-15")
            .endOfQuarter(timezone: testTimezone, calendar: testCalendar))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2021-10-01"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2021-11-15"))
    }

    func test_when_time_range_inits_with_lastQuarter_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-05-15")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastQuarter,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-01-01"))
        XCTAssertEqual(currentTimeRange.end, endDate(from: "2022-03-31"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2021-10-01"))
        XCTAssertEqual(previousTimeRange.end, endDate(from: "2021-12-31"))
    }

    func test_when_time_range_inits_with_monthToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2010-07-31")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .monthToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2010-07-01"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2010-07-31").endOfMonth(timezone: testTimezone))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2010-06-01"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2010-06-30"))
    }

    func test_when_time_range_inits_with_lastMonth_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2010-07-15")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastMonth,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2010-06-01"))
        XCTAssertEqual(currentTimeRange.end, endDate(from: "2010-06-30"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2010-05-01"))
        XCTAssertEqual(previousTimeRange.end, endDate(from: "2010-05-31"))
    }

    func test_when_time_range_inits_with_weekToDate_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .weekToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-06-27"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2022-07-01").endOfWeek(timezone: testTimezone))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-20"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2022-06-24"))
    }

    func test_when_time_range_inits_with_lastWeek_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastWeek,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-06-20"))
        XCTAssertEqual(currentTimeRange.end, endDate(from: "2022-06-26"))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-13"))
        XCTAssertEqual(previousTimeRange.end, endDate(from: "2022-06-19"))
    }

    func test_when_time_range_inits_with_today_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .today,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentTimeRange = try timeRange.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRange.unwrapPreviousTimeRange()

        // Then
        XCTAssertEqual(currentTimeRange.start, startDate(from: "2022-07-01"))
        XCTAssertEqual(currentTimeRange.end, currentDate(from: "2022-07-01").endOfDay(timezone: testTimezone))

        XCTAssertEqual(previousTimeRange.start, startDate(from: "2022-06-30"))
        XCTAssertEqual(previousTimeRange.end, currentDate(from: "2022-06-30"))
    }

    func test_when_time_range_inits_with_yesterday_then_generate_expected_ranges() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yesterday,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

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
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jan 1 - Jul 1, 2021")
    }

    func test_when_time_range_inits_with_lastYear_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastYear,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Dec 31, 2021")
        XCTAssertEqual(previousRangeDescription, "Jan 1 - Dec 31, 2020")
    }

    func test_when_time_range_inits_with_quarterToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-02-15")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .quarterToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Feb 15, 2022")
        XCTAssertEqual(previousRangeDescription, "Oct 1 - Nov 15, 2021")
    }

    func test_when_time_range_inits_with_lastQuarter_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-05-15")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastQuarter,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jan 1 - Mar 31, 2022")
        XCTAssertEqual(previousRangeDescription, "Oct 1 - Dec 31, 2021")
    }

    func test_when_time_range_inits_with_monthToDate_in_month_last_day_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-31")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .monthToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1 - 31, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 1 - 30, 2022")
    }

    func test_when_time_range_inits_with_monthToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-20")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .monthToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1 - 20, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 1 - 20, 2022")
    }

    func test_when_time_range_inits_with_lastMonth_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-31")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastMonth,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jun 1 - 30, 2022")
        XCTAssertEqual(previousRangeDescription, "May 1 - 31, 2022")
    }

    func test_when_time_range_inits_with_weekToDate_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .weekToDate,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

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
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jun 27 - Jul 2, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 20 - 25, 2022")
    }

    func test_when_time_range_inits_with_lastWeek_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-29")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastWeek,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 18 - 24, 2022")
        XCTAssertEqual(previousRangeDescription, "Jul 11 - 17, 2022")
    }

    func test_when_time_range_inits_with_lastWeek_with_different_months_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-05")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .lastWeek,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jun 27 - Jul 3, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 20 - 26, 2022")
    }

    func test_when_time_range_inits_with_today_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-01")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .today,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 30, 2022")
    }

    func test_when_time_range_inits_with_yesterday_then_generate_expected_descriptions() throws {
        // Given
        let today = currentDate(from: "2022-07-02")
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .yesterday,
                                                       currentDate: today,
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Jul 1, 2022")
        XCTAssertEqual(previousRangeDescription, "Jun 30, 2022")
    }

    func test_custom_ranges_generates_expected_descriptions() throws {
        // Given
        let start = startDate(from: "2022-12-05") ?? Date()
        let end = endDate(from: "2022-12-07") ?? Date()
        let timeRange = AnalyticsHubTimeRangeSelection(selectionType: .custom(start: start, end: end),
                                                       timezone: testTimezone,
                                                       calendar: testCalendar)

        // When
        let currentRangeDescription = timeRange.currentRangeDescription
        let previousRangeDescription = timeRange.previousRangeDescription

        // Then
        XCTAssertEqual(currentRangeDescription, "Dec 5 - 7, 2022")
        XCTAssertEqual(previousRangeDescription, "Dec 2 - 4, 2022")
    }

    private func currentDate(from date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = testTimezone
        return dateFormatter.date(from: date + "T11:30:00+0000")!
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
