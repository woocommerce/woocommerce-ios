import XCTest
@testable import Networking


/// OrderStatsV4Mapper Unit Tests
///
final class OrderStatsV4MapperTests: XCTestCase {
    /// Verifies that all of the hourly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testHourlyUnitStatFieldsAreProperlyParsed() {
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

    /// Verifies that all of the weekly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testWeeklyUnitStatFieldsAreProperlyParsed() {
        guard let weeklyStats = mapOrderStatsWithWeeklyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weeklyStats.totals.orders, 3)
        XCTAssertEqual(weeklyStats.totals.itemsSold, 5)
        XCTAssertEqual(weeklyStats.totals.grossRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.coupons, 0)
        XCTAssertEqual(weeklyStats.totals.couponDiscount, 0)
        XCTAssertEqual(weeklyStats.totals.refunds, 0)
        XCTAssertEqual(weeklyStats.totals.taxes, 0)
        XCTAssertEqual(weeklyStats.totals.shipping, 0)
        XCTAssertEqual(weeklyStats.totals.netRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.products, 2)

        XCTAssertEqual(weeklyStats.intervals.count, 2)

        let nonZeroWeek = weeklyStats.intervals[0]
        let nonZeroWeekTotals = nonZeroWeek.subtotals

        XCTAssertEqual(nonZeroWeek.interval, "2019-28")

        XCTAssertEqual(nonZeroWeekTotals.orders, 3)
        XCTAssertEqual(nonZeroWeekTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroWeekTotals.coupons, 0)
        XCTAssertEqual(nonZeroWeekTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroWeekTotals.refunds, 0)
        XCTAssertEqual(nonZeroWeekTotals.taxes, 0)
        XCTAssertEqual(nonZeroWeekTotals.shipping, 0)
        XCTAssertEqual(nonZeroWeekTotals.netRevenue, 800)
        XCTAssertNil(nonZeroWeekTotals.products)
    }
}

private extension OrderStatsV4MapperTests {
    /// Returns the OrderStatsMapper output upon receiving `order-stats-v4-hour`
    ///
    func mapOrderStatsWithHourlyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-hour")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-v4-default`
    ///
    func mapOrderStatsWithWeeklyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-defaults")
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
