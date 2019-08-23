import XCTest
@testable import Yosemite

class StatsTimeRangeTests: XCTestCase {

    func testVisitStatsQuantityOnFebInLeapYear() {
        // GMT: Saturday, February 1, 2020 12:29:29 AM
        let date = Date(timeIntervalSince1970: 1580516969)
        let timezone = TimeZone(identifier: "GMT")!
        let quantity = StatsTimeRangeV4.thisMonth.siteVisitStatsQuantity(date: date,
                                                                         siteTimezone: timezone)
        XCTAssertEqual(quantity, 29)
    }
}
