import XCTest
@testable import WooCommerce

final class DateStartAndEndTests: XCTestCase {
    private let gmtPlus8TimeZone: TimeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    // MARK: Day

    func testStartOfDay() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let startOfDay = date.startOfDay(timezone: gmtPlus8TimeZone)
        // Wednesday, August 7, 2019 12:00:00 AM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1565107200)
        XCTAssertEqual(startOfDay, expectedDate)
    }

    func testEndOfDay() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let endOfDay = date.endOfDay(timezone: gmtPlus8TimeZone)
        // Wednesday, August 7, 2019 11:59:59 PM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1565193599)
        XCTAssertEqual(endOfDay, expectedDate)
    }

    // MARK: Week

    func testStartOfWeek() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let startOfWeek = date.startOfWeek(timezone: gmtPlus8TimeZone)
        // Sunday, August 4, 2019 12:00:00 AM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1564848000)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testStartOfWeekForSunday() {
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        let date = Date(timeIntervalSince1970: 1585522799)
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfWeek = date.startOfWeek(timezone: timeZone)
        // GMT: Sunday, March 29, 2020 12:00:00 AM
        let expectedDate = Date(timeIntervalSince1970: 1585440000)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testStartOfWeekForSundayWithDailySavingTimeChange() {
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        // Rome: Sunday, March 29, 2020 11:59:59 PM
        let date = Date(timeIntervalSince1970: 1585522799)
        let timeZone = TimeZone(identifier: "Europe/Rome")!
        let startOfWeek = date.startOfWeek(timezone: timeZone)
        // GMT: Saturday, March 28, 2020 11:00:00 PM
        // Rome: Sunday, March 29, 2020 12:00:00 AM
        // In simulator, the calendar's `firstWeekday` is 1 (Sunday).
        let expectedDate = Date(timeIntervalSince1970: 1585436400)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testEndOfWeek() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let endOfWeek = date.endOfWeek(timezone: gmtPlus8TimeZone)
        // Saturday, August 10, 2019 11:59:59 PM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1565452799)
        XCTAssertEqual(endOfWeek, expectedDate)
    }

    func testEndOfWeekForSunday() {
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        let date = Date(timeIntervalSince1970: 1585522799)
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let endOfWeek = date.endOfWeek(timezone: timeZone)
        // GMT: Saturday, April 4, 2020 11:59:59 PM
        let expectedDate = Date(timeIntervalSince1970: 1586044799)
        XCTAssertEqual(endOfWeek, expectedDate)
    }

    func testEndOfWeekForSundayWithDailySavingTimeChange() {
        // GMT: Sunday, March 29, 2020 20:26:40 PM
        // Rome: Sunday March 29, 2020 21:26:40 PM
        let date = Date(timeIntervalSince1970: 1585510000)
        let timeZone = TimeZone(identifier: "Europe/Rome")!
        let startOfWeek = date.endOfWeek(timezone: timeZone)
        // GMT: Saturday, April 04, 2020 21:59:59 PM
        // Rome: Saturday April 04, 2020 23:59:59 PM
        // In simulator, the calendar's `firstWeekday` is 1 (Sunday).
        let expectedDate = Date(timeIntervalSince1970: 1586037599)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    // MARK: Month

    func testStartOfMonth() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let startOfMonth = date.startOfMonth(timezone: gmtPlus8TimeZone)
        // Thursday, August 1, 2019 12:00:00 AM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1564588800)
        XCTAssertEqual(startOfMonth, expectedDate)
    }

    func testEndOfMonth() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let endOfMonth = date.endOfMonth(timezone: gmtPlus8TimeZone)
        // Saturday, August 31, 2019 11:59:59 PM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1567267199)
        XCTAssertEqual(endOfMonth, expectedDate)
    }

    // MARK: Year

    func testStartOfYear() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let startOfYear = date.startOfYear(timezone: gmtPlus8TimeZone)
        // Tuesday, January 1, 2019 12:00:00 AM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1546272000)
        XCTAssertEqual(startOfYear, expectedDate)
    }

    func testEndOfYear() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let endOfYear = date.endOfYear(timezone: gmtPlus8TimeZone)
        // Tuesday, December 31, 2019 11:59:59 PM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1577807999)
        XCTAssertEqual(endOfYear, expectedDate)
    }
}
