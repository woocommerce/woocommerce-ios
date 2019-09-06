import XCTest
@testable import Yosemite

class OrderStatsV4Interval_DateTests: XCTestCase {
    private let mockIntervalSubtotals = OrderStatsV4Totals(totalOrders: 0, totalItemsSold: 0, grossRevenue: 0, couponDiscount: 0, totalCoupons: 0,
                                                           refunds: 0, taxes: 0, shipping: 0, netRevenue: 0, totalProducts: nil)

    func testDateStartAndDateEnd() {
        let dateInGMT = "2019-08-08 10:45:00"
        // GMT: Thursday, August 8, 2019 10:45:00 AM
        let expectedDate = Date(timeIntervalSince1970: 1565261100)
        let interval = OrderStatsV4Interval(interval: "hour", dateStart: dateInGMT, dateEnd: dateInGMT, subtotals: mockIntervalSubtotals)
        XCTAssertEqual(interval.dateStart(), expectedDate)
        XCTAssertEqual(interval.dateEnd(), expectedDate)
    }
}
