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

    func testStartOfWeekInTaipei() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Taipei (GMT+8): Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let timeZone = TimeZone(identifier: "Asia/Taipei")!
        let locale = Locale(identifier: "zh_Hant_TW")
        let startOfWeek = date.startOfWeek(timezone: timeZone, locale: locale)
        // Sunday, August 4, 2019 12:00:00 AM GMT+08:00
        // In Taipei/Taiwan, a week starts on Sunday and ends on Saturday.
        let expectedDate = Date(timeIntervalSince1970: 1564848000)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testStartOfWeekForSundayInLondon() {
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        // London: Sunday March 29, 2020 23:59:59
        let date = Date(timeIntervalSince1970: 1585522799)
        let timeZone = TimeZone(identifier: "Europe/London")!
        let locale = Locale(identifier: "en_GB")
        let startOfWeek = date.startOfWeek(timezone: timeZone, locale: locale)
        // GMT: Monday, March 23, 2020 12:00:00 AM
        // London: Monday, March 23, 2020 12:00:00 AM
        let expectedDate = Date(timeIntervalSince1970: 1584921600)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testStartOfWeekForSundayWithDailySavingTimeChange() {
        // GMT: Sunday, March 29, 2020 5:29:32 PM
        // Rome: Sunday March 29, 2020 7:29:32 PM
        let date = Date(timeIntervalSince1970: 1585502972)
        let timeZone = TimeZone(identifier: "Europe/Rome")!
        let locale = Locale(identifier: "it_IT")
        let startOfWeek = date.startOfWeek(timezone: timeZone, locale: locale)
        // GMT: Sunday, March 22, 2020 11:00:00 PM
        // Rome: Monday, March 23, 2020 12:00:00 AM
        // The first weekday is Monday for the time zone.
        let expectedDate = Date(timeIntervalSince1970: 1584918000)
        XCTAssertEqual(startOfWeek, expectedDate)
    }

    func testEndOfWeekInTaipei() {
        // GMT: Wednesday, August 7, 2019 2:27:42 AM
        // Taipei (GMT+8): Wednesday, August 7, 2019 10:27:42 AM GMT+08:00
        let date = Date(timeIntervalSince1970: 1565144862)
        let timeZone = TimeZone(identifier: "Asia/Taipei")!
        let locale = Locale(identifier: "zh_Hant_TW")
        let endOfWeek = date.endOfWeek(timezone: timeZone, locale: locale)
        // Saturday, August 10, 2019 11:59:59 PM GMT+08:00
        // In Taipei/Taiwan, a week starts on Sunday and ends on Saturday.
        let expectedDate = Date(timeIntervalSince1970: 1565452799)
        XCTAssertEqual(endOfWeek, expectedDate)
    }

    func testEndOfWeekForSundayInLondon() {
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        // London: Sunday March 29, 2020 23:59:59
        let date = Date(timeIntervalSince1970: 1585522799)
        let timeZone = TimeZone(identifier: "Europe/London")!
        let locale = Locale(identifier: "en_GB")
        let endOfWeek = date.endOfWeek(timezone: timeZone, locale: locale)
        // GMT: Sunday, March 29, 2020 10:59:59 PM
        // London: Sunday March 29, 2020 23:59:59
        // In London/UK, a week starts on Monday and ends on Sunday.
        let expectedDate = Date(timeIntervalSince1970: 1585522799)
        XCTAssertEqual(endOfWeek, expectedDate)
    }

    func testEndOfWeekForSundayWithDailySavingTimeChange() {
        // GMT: Sunday, March 29, 2020 20:26:40 PM
        // Rome: Sunday March 29, 2020 21:26:40 PM
        let date = Date(timeIntervalSince1970: 1585510000)
        let timeZone = TimeZone(identifier: "Europe/Rome")!
        let locale = Locale(identifier: "it_IT")
        let endOfWeek = date.endOfWeek(timezone: timeZone, locale: locale)
        // GMT: Sunday, March 29, 2020 9:59:59 PM
        // Rome: Monday, March 29, 2020 11:59:59 PM
        // In Rome/Italy, a week starts on Monday and ends on Sunday.
        let expectedDate = Date(timeIntervalSince1970: 1585519199)
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
