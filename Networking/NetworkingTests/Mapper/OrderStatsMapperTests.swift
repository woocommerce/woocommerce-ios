import XCTest
@testable import Networking


/// OrderStatsMapper Unit Tests
///
class OrderStatsMapperTests: XCTestCase {

    /// Verifies that all of the day unit OrderStats fields are parsed correctly.
    ///
    func testDayUnitStatFieldsAreProperlyParsed() {
        guard let dayStats = mapOrderStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.unit, "day")
        XCTAssertEqual(dayStats.date, "2018-06-08")
        XCTAssertEqual(dayStats.quantity, "31")
        XCTAssertEqual(dayStats.fields.count, 18)
        XCTAssertEqual(dayStats.orderStatsItems!.count, 31)
        XCTAssertEqual(dayStats.totalOrders, 9)
        XCTAssertEqual(dayStats.totalProducts, 13)
        XCTAssertEqual(dayStats.totalGrossSales, 439.23)
        XCTAssertEqual(dayStats.totalNetSales, 438.24)
        XCTAssertEqual(dayStats.averageGrossSales, 14.1687)
        XCTAssertEqual(dayStats.averageNetSales, 14.1368)
        XCTAssertEqual(dayStats.averageOrders, 0.2903)
        XCTAssertEqual(dayStats.averageProducts, 0.4194)
    }

    /// Verifies that all of the week unit OrderStats fields are parsed correctly.
    ///
    func testWeekUnitStatFieldsAreProperlyParsed() {
        guard let weekStats = mapOrderStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.unit, "week")
        XCTAssertEqual(weekStats.date, "2018-W30")
        XCTAssertEqual(weekStats.quantity, "31")
        XCTAssertEqual(weekStats.fields.count, 18)
        XCTAssertEqual(weekStats.orderStatsItems!.count, 31)
        XCTAssertEqual(weekStats.totalOrders, 65)
        XCTAssertEqual(weekStats.totalProducts, 87)
        XCTAssertEqual(weekStats.totalGrossSales, 2858.52)
        XCTAssertEqual(weekStats.totalNetSales, 2833.55)
        XCTAssertEqual(weekStats.averageGrossSales, 92.2103)
        XCTAssertEqual(weekStats.averageNetSales, 91.4048)
        XCTAssertEqual(weekStats.averageOrders, 2.0968)
        XCTAssertEqual(weekStats.averageProducts, 2.8065)
    }

    /// Verifies that all of the month unit OrderStats fields are parsed correctly.
    ///
    func testMonthUnitStatFieldsAreProperlyParsed() {
        guard let monthStats = mapOrderStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.unit, "month")
        XCTAssertEqual(monthStats.date, "2018-06")
        XCTAssertEqual(monthStats.quantity, "12")
        XCTAssertEqual(monthStats.fields.count, 18)
        XCTAssertEqual(monthStats.orderStatsItems!.count, 12)
        XCTAssertEqual(monthStats.totalOrders, 159)
        XCTAssertEqual(monthStats.totalProducts, 243)
        XCTAssertEqual(monthStats.totalGrossSales, 6830.590000000002)
        XCTAssertEqual(monthStats.totalNetSales, 6717.232000000002)
        XCTAssertEqual(monthStats.averageGrossSales, 569.2158)
        XCTAssertEqual(monthStats.averageNetSales, 559.7693)
        XCTAssertEqual(monthStats.averageOrders, 13.25)
        XCTAssertEqual(monthStats.averageProducts, 20.25)
    }

    /// Verifies that all of the year unit OrderStats fields are parsed correctly.
    ///
    func testYearUnitStatFieldsAreProperlyParsed() {
        guard let yearStats = mapOrderStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.unit, "year")
        XCTAssertEqual(yearStats.date, "2018")
        XCTAssertEqual(yearStats.quantity, "4")
        XCTAssertEqual(yearStats.fields.count, 18)
        XCTAssertEqual(yearStats.orderStatsItems!.count, 4)
        XCTAssertEqual(yearStats.totalOrders, 293)
        XCTAssertEqual(yearStats.totalProducts, 626)
        XCTAssertEqual(yearStats.totalGrossSales, 10928.91999999999)
        XCTAssertEqual(yearStats.totalNetSales, 10684.27199999999)
        XCTAssertEqual(yearStats.averageGrossSales, 2732.23)
        XCTAssertEqual(yearStats.averageNetSales, 2671.068)
        XCTAssertEqual(yearStats.averageOrders, 73.25)
        XCTAssertEqual(yearStats.averageProducts, 156.5)
    }
}


/// Private Methods.
///
private extension OrderStatsMapperTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String) -> OrderStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderStatsMapper().map(response: response)
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-day`
    ///
    func mapOrderStatsWithDayUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-day")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-week`
    ///
    func mapOrderStatsWithWeekUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-week")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-month`
    ///
    func mapOrderStatsWithMonthUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-month")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-year`
    ///
    func mapOrderStatsWithYearUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-year")
    }
}
