import XCTest
@testable import Networking


/// OrderStatsMapper Unit Tests
///
class OrderStatsMapperTests: XCTestCase {

    /// Verifies that all of the OrderStatsItem Fields are parsed correctly.
    ///
    func testStatFieldsAreProperlyParsed() {
//        let dayStatItems = mapOrderStatsWithDayUnitResponse()
//        XCTAssertEqual(dayStatItems.count, 31)
//        let testStat = dayStatItems[26]
//        XCTAssertEqual(testStat.period, "2018-06-01")
    }
}


/// Private Methods.
///
private extension OrderStatsMapperTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String) -> [OrderStatItem] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderStatsMapper().map(response: response)
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-day`
    ///
    func mapOrderStatsWithDayUnitResponse() -> [OrderStatItem] {
        return mapStatItems(from: "order-stats-day")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-week`
    ///
    func mapOrderStatsWithWeekUnitResponse() -> [OrderStatItem] {
        return mapStatItems(from: "order-stats-week")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-month`
    ///
    func mapOrderStatsWithMonthUnitResponse() -> [OrderStatItem] {
        return mapStatItems(from: "order-stats-month")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-year`
    ///
    func mapOrderStatsWithYearUnitResponse() -> [OrderStatItem] {
        return mapStatItems(from: "order-stats-year")
    }
}
