import XCTest
@testable import WooCommerce

class DateStartAndEndTests: XCTestCase {
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

    func testEndOfWeek() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Your time zone: Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let endOfWeek = date.endOfWeek(timezone: gmtPlus8TimeZone)
        // Saturday, August 10, 2019 11:59:59 PM GMT+08:00
        let expectedDate = Date(timeIntervalSince1970: 1565452799)
        XCTAssertEqual(endOfWeek, expectedDate)
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
