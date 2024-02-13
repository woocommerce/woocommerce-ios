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
