import XCTest
@testable import Yosemite

class OrderStatsV4Interval_DateTests: XCTestCase {
    private let mockIntervalSubtotals = OrderStatsV4Totals(totalOrders: 0, totalItemsSold: 0, grossRevenue: 0, couponDiscount: 0, totalCoupons: 0,
                                                           refunds: 0, taxes: 0, shipping: 0, netRevenue: 0, totalProducts: nil)

    func testDateStartAndDateEnd() {
        let dateStringInSiteTimeZone = "2019-08-08 10:45:00"
        // GMT: Thursday, August 8, 2019 10:45:00 AM
        let expectedDateInGMT = Date(timeIntervalSince1970: 1565261100)
        // Adjusts the GMT date by the current time zone GMT offset to have the same "time" (day/hour/minute/second) in the current time zone.
        // (e.g. expectedDate` will be "2019-08-08 10:45:00" in the current device time zone)
        let expectedDate = expectedDateInGMT.addingTimeInterval(-TimeInterval(TimeZone.current.secondsFromGMT(for: expectedDateInGMT)))
        let interval = OrderStatsV4Interval(interval: "hour", dateStart: dateStringInSiteTimeZone, dateEnd: dateStringInSiteTimeZone, subtotals: mockIntervalSubtotals)
        XCTAssertEqual(interval.dateStart(), expectedDate)
        XCTAssertEqual(interval.dateEnd(), expectedDate)
    }
}
