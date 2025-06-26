import XCTest
@testable import Yosemite

final class StatsTimeRangeTests: XCTestCase {

    func testVisitStatsQuantityOnFebInLeapYear() {
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let date = Date(timeIntervalSince1970: 1580516969)
        let timezone = TimeZone(identifier: "GMT")!
        let quantity = StatsTimeRangeV4.thisMonth.siteVisitStatsQuantity(date: date,
                                                                         siteTimezone: timezone)
        XCTAssertEqual(quantity, 29)
    }

    // MARK: `intervalGranularity` for custom range

    func test_intervalGranularity_for_dates_with_days_difference_greater_than_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(365*3+1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.intervalGranularity, .yearly)
    }

    func test_intervalGranularity_for_dates_with_days_difference_from_91_to_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 91...365*3))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.intervalGranularity, .monthly)
    }

    func test_intervalGranularity_for_dates_with_days_difference_from_29_to_90() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 29...90))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.intervalGranularity, .weekly)
    }

    func test_intervalGranularity_for_dates_with_days_difference_from_1_to_28() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 1...28))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.intervalGranularity, .daily)
    }

    func test_intervalGranularity_for_a_same_day_range() {
        // Given
        // GMT: March 4 2024 00:00:00
        let startDate = Date(timeIntervalSince1970: 1709510400)
        // GMT: March 4 2024 23:59:59
        let endDate = Date(timeIntervalSince1970: 1709596799)

        // When
        let range: StatsTimeRangeV4 = .custom(from: startDate, to: endDate)

        // Then
        XCTAssertEqual(range.intervalGranularity, .hourly)
    }

    // MARK: `siteVisitStatsGranularity` for custom range

    func test_siteVisitStatsGranularity_for_dates_with_days_difference_greater_than_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(365*3+1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.siteVisitStatsGranularity, .year)
    }

    func test_siteVisitStatsGranularity_for_dates_with_days_difference_from_91_to_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 91...365*3))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.siteVisitStatsGranularity, .month)
    }

    func test_siteVisitStatsGranularity_for_dates_with_days_difference_from_29_to_90() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 29...90))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.siteVisitStatsGranularity, .week)
    }

    func test_siteVisitStatsGranularity_for_dates_with_days_difference_from_1_to_28() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 1...28))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.siteVisitStatsGranularity, .day)
    }

    func test_siteVisitStatsGranularity_for_a_same_day_range() {
        // Given
        // GMT: March 4 2024 00:00:00
        let startDate = Date(timeIntervalSince1970: 1709510400)
        // GMT: March 4 2024 23:59:59
        let endDate = Date(timeIntervalSince1970: 1709596799)

        // When
        let range: StatsTimeRangeV4 = .custom(from: startDate, to: endDate)

        // Then
        XCTAssertEqual(range.siteVisitStatsGranularity, .day)
    }

    // MARK: `topEarnerStatsGranularity` for custom range

    func test_topEarnerStatsGranularity_for_dates_with_days_difference_greater_than_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(365*3+1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.topEarnerStatsGranularity, .year)
    }

    func test_topEarnerStatsGranularity_for_dates_with_days_difference_from_91_to_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 91...365*3))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.topEarnerStatsGranularity, .month)
    }

    func test_topEarnerStatsGranularity_for_dates_with_days_difference_from_29_to_90() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 29...90))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.topEarnerStatsGranularity, .week)
    }

    func test_topEarnerStatsGranularity_for_dates_with_days_difference_from_2_to_28() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 2...28))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.topEarnerStatsGranularity, .day)
    }

    func test_topEarnerStatsGranularity_for_dates_with_days_difference_less_than_2() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.topEarnerStatsGranularity, .day)
    }

    // MARK: `summaryStatsGranularity` for custom range

    func test_summaryStatsGranularity_for_dates_with_days_difference_greater_than_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(365*3+1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.summaryStatsGranularity, .year)
    }

    func test_summaryStatsGranularity_for_dates_with_days_difference_from_91_to_3_years() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 91...365*3))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.summaryStatsGranularity, .month)
    }

    func test_summaryStatsGranularity_for_dates_with_days_difference_from_29_to_90() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 29...90))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.summaryStatsGranularity, .week)
    }

    func test_summaryStatsGranularity_for_dates_with_days_difference_from_2_to_28() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(Int.random(in: 2...28))

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.summaryStatsGranularity, .day)
    }

    func test_summaryStatsGranularity_for_dates_with_days_difference_less_than_2() {
        // Given
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let toDate = fromDate.addingDays(1)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.summaryStatsGranularity, .day)
    }
    // MARK: Custom range

    func test_initializing_custom_range_from_rawValue() {
        // Given

        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let fromDateString = DateFormatter.Defaults.yearMonthDayDateFormatter.string(from: fromDate)

        // GMT: Tuesday, February 13, 2024 2:47:04 AM
        let toDate = Date(timeIntervalSince1970: 1707792424)
        let toDateString = DateFormatter.Defaults.yearMonthDayDateFormatter.string(from: toDate)

        // When
        let range = StatsTimeRangeV4(rawValue: "custom_\(fromDateString)_\(toDateString)")

        // Then
        XCTAssertEqual(range, .custom(from: fromDate, to: toDate))
    }

    func test_getting_rawValue_from_custom_range() {
        // Given

        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let fromDate = Date(timeIntervalSince1970: 1580516969)
        let fromDateString = DateFormatter.Defaults.yearMonthDayDateFormatter.string(from: fromDate)

        // GMT: Tuesday, February 13, 2024 2:47:04 AM
        let toDate = Date(timeIntervalSince1970: 1707792424)
        let toDateString = DateFormatter.Defaults.yearMonthDayDateFormatter.string(from: toDate)

        // When
        let range: StatsTimeRangeV4 = .custom(from: fromDate, to: toDate)

        // Then
        XCTAssertEqual(range.rawValue, "custom_\(fromDateString)_\(toDateString)")
    }
}
