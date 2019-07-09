import XCTest
@testable import Networking


/// OrderStatsV4Mapper Unit Tests
///
final class OrderStatsV4MapperTests: XCTestCase {
    /// Verifies that all of the day unit OrderStats fields are parsed correctly.
    ///
    func testDayUnitStatFieldsAreProperlyParsed() {
        guard let hourlyStats = mapOrderStatsWithHourlyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(hourlyStats.totals.orders, 3)
        XCTAssertEqual(hourlyStats.totals.itemsSold, 5)
        XCTAssertEqual(hourlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.coupons, 0)
        XCTAssertEqual(hourlyStats.totals.couponDiscount, 0)
        XCTAssertEqual(hourlyStats.totals.refunds, 0)
        XCTAssertEqual(hourlyStats.totals.taxes, 0)
        XCTAssertEqual(hourlyStats.totals.shipping, 0)
        XCTAssertEqual(hourlyStats.totals.netRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.products, 2)

        XCTAssertEqual(hourlyStats.intervals.count, 24)

        let nonZeroHour = hourlyStats.intervals[13]
        let nonZeroHourTotals = nonZeroHour.subtotals

        XCTAssertEqual(nonZeroHour.interval, "2019-07-09 13")

        XCTAssertEqual(nonZeroHourTotals.orders, 2)
        XCTAssertEqual(nonZeroHourTotals.grossRevenue, 350)
        XCTAssertEqual(nonZeroHourTotals.coupons, 0)
        XCTAssertEqual(nonZeroHourTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroHourTotals.refunds, 0)
        XCTAssertEqual(nonZeroHourTotals.taxes, 0)
        XCTAssertEqual(nonZeroHourTotals.shipping, 0)
        XCTAssertEqual(nonZeroHourTotals.netRevenue, 350)
        XCTAssertNil(nonZeroHourTotals.products)
    }
}

private extension OrderStatsV4MapperTests {
    /// Returns the OrderStatsMapper output upon receiving `order-stats-day`
    ///
    func mapOrderStatsWithHourlyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-hour")
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String) -> OrderStatsV4? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderStatsV4Mapper().map(response: response)
    }
}
