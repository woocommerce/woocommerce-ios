import XCTest
@testable import Networking


/// OrderStatsV4Mapper Unit Tests
///
final class OrderStatsV4MapperTests: XCTestCase {
    private struct Constants {
        static let siteID: Int64 = 1234
    }

    /// Verifies that all of the hourly unit OrderStatsV4 fields are parsed correctly.
    ///
    func test_hourly_unit_stat_fields_are_properly_parsed() async throws {
        let hourlyStats = try await mapOrderStatsWithHourlyUnitResponse()

        XCTAssertEqual(hourlyStats.siteID, Constants.siteID)
        XCTAssertEqual(hourlyStats.granularity, .hourly)

        XCTAssertEqual(hourlyStats.totals.totalOrders, 3)
        XCTAssertEqual(hourlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(hourlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.netRevenue, 800)
        XCTAssertEqual(hourlyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(hourlyStats.intervals.count, 24)

        let nonZeroHour = hourlyStats.intervals[13]
        let nonZeroHourTotals = nonZeroHour.subtotals

        XCTAssertEqual(nonZeroHour.interval, "2019-07-09 13")

        XCTAssertEqual(nonZeroHourTotals.totalOrders, 2)
        XCTAssertEqual(nonZeroHourTotals.grossRevenue, 350)
        XCTAssertEqual(nonZeroHourTotals.netRevenue, 350)
        XCTAssertEqual(nonZeroHourTotals.averageOrderValue, 175)
    }

    /// Verifies that all of the daily unit OrderStatsV4 fields are parsed correctly.
    ///
    func test_daily_unit_stat_fields_are_properly_parsed() async throws {
        let dailyStats = try await mapOrderStatsWithDailyUnitResponse()

        XCTAssertEqual(dailyStats.siteID, Constants.siteID)
        XCTAssertEqual(dailyStats.granularity, .daily)

        XCTAssertEqual(dailyStats.totals.totalOrders, 3)
        XCTAssertEqual(dailyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(dailyStats.totals.grossRevenue, 800)
        XCTAssertEqual(dailyStats.totals.netRevenue, 800)
        XCTAssertEqual(dailyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(dailyStats.intervals.count, 1)

        let nonZeroDay = dailyStats.intervals[0]
        let nonZeroDayTotals = nonZeroDay.subtotals

        XCTAssertEqual(nonZeroDay.interval, "2019-07-09")

        XCTAssertEqual(nonZeroDayTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroDayTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroDayTotals.netRevenue, 800)
        XCTAssertEqual(nonZeroDayTotals.averageOrderValue, 266)
    }

    /// Verifies that all of the weekly unit OrderStatsV4 fields are parsed correctly.
    ///
    func test_weekly_unit_stat_fields_are_properly_parsed() async throws {
        let weeklyStats = try await mapOrderStatsWithWeeklyUnitResponse()

        XCTAssertEqual(weeklyStats.siteID, Constants.siteID)
        XCTAssertEqual(weeklyStats.granularity, .weekly)

        XCTAssertEqual(weeklyStats.totals.totalOrders, 3)
        XCTAssertEqual(weeklyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(weeklyStats.totals.grossRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.netRevenue, 800)
        XCTAssertEqual(weeklyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(weeklyStats.intervals.count, 2)

        let nonZeroWeek = weeklyStats.intervals[0]
        let nonZeroWeekTotals = nonZeroWeek.subtotals

        XCTAssertEqual(nonZeroWeek.interval, "2019-28")

        XCTAssertEqual(nonZeroWeekTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroWeekTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroWeekTotals.netRevenue, 800)
        XCTAssertEqual(nonZeroWeekTotals.averageOrderValue, 266)
    }

    /// Verifies that all of the monthly unit OrderStatsV4 fields are parsed correctly.
    ///
    func test_monthly_unit_stat_fields_are_properly_parsed() async throws {
        let monthlyStats = try await mapOrderStatsWithMonthlyUnitResponse()

        XCTAssertEqual(monthlyStats.siteID, Constants.siteID)
        XCTAssertEqual(monthlyStats.granularity, .monthly)

        XCTAssertEqual(monthlyStats.totals.totalOrders, 3)
        XCTAssertEqual(monthlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(monthlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(monthlyStats.totals.netRevenue, 800)
        XCTAssertEqual(monthlyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(monthlyStats.intervals.count, 1)

        let nonZeroMonth = monthlyStats.intervals[0]
        let nonZeroMonthTotals = nonZeroMonth.subtotals

        XCTAssertEqual(nonZeroMonth.interval, "2019-07")

        XCTAssertEqual(nonZeroMonthTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroMonthTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroMonthTotals.netRevenue, 800)
        XCTAssertEqual(nonZeroMonthTotals.averageOrderValue, 266)
    }

    /// Verifies that all of the yearly unit OrderStatsV4 fields are parsed correctly.
    ///
    func test_yearly_unit_stat_fields_are_properly_parsed() async throws {
        let yearlyStats = try await mapOrderStatsWithYearlyUnitResponse()

        XCTAssertEqual(yearlyStats.siteID, Constants.siteID)
        XCTAssertEqual(yearlyStats.granularity, .yearly)

        XCTAssertEqual(yearlyStats.totals.totalOrders, 3)
        XCTAssertEqual(yearlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(yearlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.netRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(yearlyStats.intervals.count, 1)

        let nonZeroYear = yearlyStats.intervals[0]
        let nonZeroYearTotals = nonZeroYear.subtotals

        XCTAssertEqual(nonZeroYear.interval, "2019")

        XCTAssertEqual(nonZeroYearTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroYearTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroYearTotals.netRevenue, 800)
        XCTAssertEqual(nonZeroYearTotals.averageOrderValue, 266)
    }

    /// Verifies that all of the yearly unit OrderStatsV4 fields are parsed correctly
    /// if the response contains no data envelope.
    ///
    func test_yearly_unit_stat_fields_are_properly_parsed_without_data_envelope() async throws {
        let yearlyStats = try await mapOrderStatsWithYearlyUnitResponseWithoutDataEnvelope()

        XCTAssertEqual(yearlyStats.siteID, Constants.siteID)
        XCTAssertEqual(yearlyStats.granularity, .yearly)

        XCTAssertEqual(yearlyStats.totals.totalOrders, 3)
        XCTAssertEqual(yearlyStats.totals.totalItemsSold, 5)
        XCTAssertEqual(yearlyStats.totals.grossRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.netRevenue, 800)
        XCTAssertEqual(yearlyStats.totals.averageOrderValue, 266)

        XCTAssertEqual(yearlyStats.intervals.count, 1)

        let nonZeroYear = yearlyStats.intervals[0]
        let nonZeroYearTotals = nonZeroYear.subtotals

        XCTAssertEqual(nonZeroYear.interval, "2019")

        XCTAssertEqual(nonZeroYearTotals.totalOrders, 3)
        XCTAssertEqual(nonZeroYearTotals.grossRevenue, 800)
        XCTAssertEqual(nonZeroYearTotals.netRevenue, 800)
        XCTAssertEqual(nonZeroYearTotals.averageOrderValue, 266)
    }
}

private extension OrderStatsV4MapperTests {
    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-hour`
    ///
    func mapOrderStatsWithHourlyUnitResponse() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-hour", granularity: .hourly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-default`
    ///
    func mapOrderStatsWithDailyUnitResponse() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-daily", granularity: .daily)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-default`
    ///
    func mapOrderStatsWithWeeklyUnitResponse() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-defaults", granularity: .weekly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-month`
    ///
    func mapOrderStatsWithMonthlyUnitResponse() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-month", granularity: .monthly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-year`
    ///
    func mapOrderStatsWithYearlyUnitResponse() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-year", granularity: .yearly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `order-stats-v4-year-without-data`
    ///
    func mapOrderStatsWithYearlyUnitResponseWithoutDataEnvelope() async throws -> OrderStatsV4 {
        try await mapStatItems(from: "order-stats-v4-year-without-data", granularity: .yearly)
    }

    /// Returns the OrderStatsV4Mapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String, granularity: StatsGranularityV4) async throws -> OrderStatsV4 {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await OrderStatsV4Mapper(siteID: Constants.siteID,
                                       granularity: granularity).map(response: response)
    }

    struct FileNotFoundError: Error {}
}
