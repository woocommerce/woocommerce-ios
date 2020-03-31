import XCTest
@testable import Yosemite

class OrderStatsV4Interval_DateTests: XCTestCase {
    private let mockIntervalSubtotals = OrderStatsV4Totals(totalOrders: 0, totalItemsSold: 0, grossRevenue: 0, couponDiscount: 0, totalCoupons: 0,
                                                           refunds: 0, taxes: 0, shipping: 0, netRevenue: 0, totalProducts: nil)

    func testDateStartAndDateEnd() {
        let dateStringInSiteTimeZone = "2019-08-08 10:45:00"
        let interval = OrderStatsV4Interval(interval: "hour",
                                            dateStart: dateStringInSiteTimeZone,
                                            dateEnd: dateStringInSiteTimeZone,
                                            subtotals: mockIntervalSubtotals)
        [interval.dateStart(), interval.dateEnd()].compactMap { $0 }.forEach { date in
            let dateComponents = Calendar.current.dateComponents(in: .current, from: date)
            XCTAssertEqual(dateComponents.year, 2019)
            XCTAssertEqual(dateComponents.month, 8)
            XCTAssertEqual(dateComponents.day, 8)
            XCTAssertEqual(dateComponents.hour, 10)
            XCTAssertEqual(dateComponents.minute, 45)
            XCTAssertEqual(dateComponents.second, 0)
        }
    }
}
