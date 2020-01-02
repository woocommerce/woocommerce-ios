import XCTest
@testable import Networking


/// OrderStatsV4Mapper Unit Tests
///
final class OrderStatsV4MapperTests: XCTestCase {
    private struct Constants {
        static let siteID: Int64 = 1234
        static let hourlyGranularity = StatsGranularityV4.hourly
        static let dailyGranularity = StatsGranularityV4.daily
        static let weeklyGranularity = StatsGranularityV4.weekly
        static let monthlyGranularity = StatsGranularityV4.monthly
        static let yearlyGranularity = StatsGranularityV4.yearly
    }

    /// Verifies that all of the hourly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testHourlyUnitStatFieldsAreProperlyParsed() {
        guard let hourlyStats = mapOrderStatsWithHourlyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(hourlyStats.siteID, Constants.siteID)
        XCTAssertEqual(hourlyStats.granularity, .hourly)

        XCTAssertEqual(hourlyStats.totals.totalOrders, 3)
        XCTAssertEqual(hourlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(hourlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.totalCoupons, 0)
        XCTAssertEqual(hourlyStats.totals.couponDiscount, 0)
        XCTAssertEqual(hourlyStats.totals.refunds, 0)
        XCTAssertEqual(hourlyStats.totals.taxes, 0)
        XCTAssertEqual(hourlyStats.totals.shipping, 0)
        XCTAssertEqual(hourlyStats.totals.netRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.totalProducts, 2)

        XCTAssertEqual(hourlyStats.intervals.count, 24)

        let nonZeroHour = hourlyStats.intervals[13]
        let nonZeroHourTotals = nonZeroHour.subtotals

        XCTAssertEqual(nonZeroHour.interval, "2019-07-09 13")

        XCTAssertEqual(nonZeroHourTotals.totalOrders, 2)
        XCTAssertEqual(nonZeroHourTotals.grossRevenue, 350)
        XCTAssertEqual(nonZeroHourTotals.totalCoupons, 0)
        XCTAssertEqual(nonZeroHourTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroHourTotals.refunds, 0)
        XCTAssertEqual(nonZeroHourTotals.taxes, 0)
        XCTAssertEqual(nonZeroHourTotals.shipping, 0)
        XCTAssertEqual(nonZeroHourTotals.netRevenue, 350)
        XCTAssertNil(nonZeroHourTotals.totalProducts)
    }

    /// Verifies that all of the daily unit OrderStatsV4 fields are parsed correctly.
    ///
    func testDailyUnitStatFieldsAreProperlyParsed() {
        guard let dailyStats = mapOrderStatsWithDailyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dailyStats.siteID, Constants.siteID)
        XCTAssertEqual(dailyStats.granularity, .daily)

        XCTAssertEqual(dailyStats.totals.totalOrders, 3)
        XCTAssertEqual(dailyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(dailyStats.totals.grossRevenue, 800)
        XCTAssertEqual(dailyStats.totals.totalCoupons, 0)
        XCTAssertEqual(dailyStats.totals.couponDiscount, 0)
        XCTAssertEqual(dailyStats.totals.refunds, 0)
        XCTAssertEqual(dailyStats.totals.taxes, 0)
        XCTAssertEqual(dailyStats.totals.shipping, 0)
        XCTAssertEqual(dailyStats.totals.netRevenue, 800)
        XCTAssertEqual(dailyStats.totals.totalProducts, 2)

        XCTAssertEqual(dailyStats.intervals.count, 1)

        let nonZeroDay = dailyStats.intervals[0]
        let nonZeroDayTotals = nonZeroDay.subtotals

        XCTAssertEqual(nonZeroDay.interval, "2019-07-09")

        XCTAssertEqual(nonZeroDayTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroDayTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroDayTotals.totalCoupons, 0)
        XCTAssertEqual(nonZeroDayTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroDayTotals.refunds, 0)
        XCTAssertEqual(nonZeroDayTotals.taxes, 0)
        XCTAssertEqual(nonZeroDayTotals.shipping, 0)
        XCTAssertEqual(nonZeroDayTotals.netRevenue, 800)
        XCTAssertNil(nonZeroDayTotals.totalProducts)
    }

    /// Verifies that all of the weekly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testWeeklyUnitStatFieldsAreProperlyParsed() {
        guard let weeklyStats = mapOrderStatsWithWeeklyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weeklyStats.siteID, Constants.siteID)
        XCTAssertEqual(weeklyStats.granularity, .weekly)

        XCTAssertEqual(weeklyStats.totals.totalOrders, 3)
        XCTAssertEqual(weeklyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(weeklyStats.totals.grossRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.totalCoupons, 0)
        XCTAssertEqual(weeklyStats.totals.couponDiscount, 0)
        XCTAssertEqual(weeklyStats.totals.refunds, 0)
        XCTAssertEqual(weeklyStats.totals.taxes, 0)
        XCTAssertEqual(weeklyStats.totals.shipping, 0)
        XCTAssertEqual(weeklyStats.totals.netRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.totalProducts, 2)

        XCTAssertEqual(weeklyStats.intervals.count, 2)

        let nonZeroWeek = weeklyStats.intervals[0]
        let nonZeroWeekTotals = nonZeroWeek.subtotals

        XCTAssertEqual(nonZeroWeek.interval, "2019-28")

        XCTAssertEqual(nonZeroWeekTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroWeekTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroWeekTotals.totalCoupons, 0)
        XCTAssertEqual(nonZeroWeekTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroWeekTotals.refunds, 0)
        XCTAssertEqual(nonZeroWeekTotals.taxes, 0)
        XCTAssertEqual(nonZeroWeekTotals.shipping, 0)
        XCTAssertEqual(nonZeroWeekTotals.netRevenue, 800)
        XCTAssertNil(nonZeroWeekTotals.totalProducts)
    }

    /// Verifies that all of the monthly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testMonthlyUnitStatFieldsAreProperlyParsed() {
        guard let monthlyStats = mapOrderStatsWithMonthlyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthlyStats.siteID, Constants.siteID)
        XCTAssertEqual(monthlyStats.granularity, .monthly)

        XCTAssertEqual(monthlyStats.totals.totalOrders, 3)
        XCTAssertEqual(monthlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(monthlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(monthlyStats.totals.totalCoupons, 0)
        XCTAssertEqual(monthlyStats.totals.couponDiscount, 0)
        XCTAssertEqual(monthlyStats.totals.refunds, 0)
        XCTAssertEqual(monthlyStats.totals.taxes, 0)
        XCTAssertEqual(monthlyStats.totals.shipping, 0)
        XCTAssertEqual(monthlyStats.totals.netRevenue, 800)
        XCTAssertEqual(monthlyStats.totals.totalProducts, 2)

        XCTAssertEqual(monthlyStats.intervals.count, 1)

        let nonZeroMonth = monthlyStats.intervals[0]
        let nonZeroMonthTotals = nonZeroMonth.subtotals

        XCTAssertEqual(nonZeroMonth.interval, "2019-07")

        XCTAssertEqual(nonZeroMonthTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroMonthTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroMonthTotals.totalCoupons, 0)
        XCTAssertEqual(nonZeroMonthTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroMonthTotals.refunds, 0)
        XCTAssertEqual(nonZeroMonthTotals.taxes, 0)
        XCTAssertEqual(nonZeroMonthTotals.shipping, 0)
        XCTAssertEqual(nonZeroMonthTotals.netRevenue, 800)
        XCTAssertNil(nonZeroMonthTotals.totalProducts)
    }

    /// Verifies that all of the yearly unit OrderStatsV4 fields are parsed correctly.
    ///
    func testYearlyUnitStatFieldsAreProperlyParsed() {
        guard let yearlyStats = mapOrderStatsWithYearlyUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearlyStats.siteID, Constants.siteID)
        XCTAssertEqual(yearlyStats.granularity, .yearly)

        XCTAssertEqual(yearlyStats.totals.totalOrders, 3)
        XCTAssertEqual(yearlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(yearlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.totalCoupons, 0)
        XCTAssertEqual(yearlyStats.totals.couponDiscount, 0)
        XCTAssertEqual(yearlyStats.totals.refunds, 0)
        XCTAssertEqual(yearlyStats.totals.taxes, 0)
        XCTAssertEqual(yearlyStats.totals.shipping, 0)
        XCTAssertEqual(yearlyStats.totals.netRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.totalProducts, 2)

        XCTAssertEqual(yearlyStats.intervals.count, 1)

        let nonZeroYear = yearlyStats.intervals[0]
        let nonZeroYearTotals = nonZeroYear.subtotals

        XCTAssertEqual(nonZeroYear.interval, "2019")

        XCTAssertEqual(nonZeroYearTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroYearTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroYearTotals.totalCoupons, 0)
        XCTAssertEqual(nonZeroYearTotals.couponDiscount, 0)
        XCTAssertEqual(nonZeroYearTotals.refunds, 0)
        XCTAssertEqual(nonZeroYearTotals.taxes, 0)
        XCTAssertEqual(nonZeroYearTotals.shipping, 0)
        XCTAssertEqual(nonZeroYearTotals.netRevenue, 800)
        XCTAssertNil(nonZeroYearTotals.totalProducts)
    }
}

private extension OrderStatsV4MapperTests {
    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-hour`
    ///
    func mapOrderStatsWithHourlyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-hour", granularity: .hourly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-default`
    ///
    func mapOrderStatsWithDailyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-daily", granularity: .daily)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-default`
    ///
    func mapOrderStatsWithWeeklyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-defaults", granularity: .weekly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-month`
    ///
    func mapOrderStatsWithMonthlyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-month", granularity: .monthly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-year`
    ///
    func mapOrderStatsWithYearlyUnitResponse() -> OrderStatsV4? {
        return mapStatItems(from: "order-stats-v4-year", granularity: .yearly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String, granularity: StatsGranularityV4) -> OrderStatsV4? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderStatsV4Mapper(siteID: Constants.siteID,
                                       granularity: granularity).map(response: response)
    }
}
