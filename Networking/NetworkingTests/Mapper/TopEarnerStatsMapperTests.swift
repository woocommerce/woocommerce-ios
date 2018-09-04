import XCTest
@testable import Networking


/// TopEarnerStatsMapper Unit Tests
///
class TopEarnerStatsMapperTests: XCTestCase {

    /// Verifies that all of the day unit TopEarnerStats fields are parsed correctly.
    ///
    func testDayUnitStatFieldsAreProperlyParsed() {
        guard let dayStats = mapTopEarnerStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        // TODO: Complete this test!
    }

    /// Verifies that all of the week unit TopEarnerStats fields are parsed correctly.
    ///
    func testWeekUnitStatFieldsAreProperlyParsed() {
        guard let weekStats = mapTopEarnerStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        // TODO: Complete this test!
    }

    /// Verifies that all of the month unit TopEarnerStats fields are parsed correctly.
    ///
    func testMonthUnitStatFieldsAreProperlyParsed() {
        guard let monthStats = mapTopEarnerStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        // TODO: Complete this test!
    }

    /// Verifies that all of the year unit TopEarnerStats fields are parsed correctly.
    ///
    func testYearUnitStatFieldsAreProperlyParsed() {
        guard let yearStats = mapTopEarnerStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }
    }

    // TODO: Complete this test!
}


/// Private Methods
///
private extension TopEarnerStatsMapperTests {

    /// Returns the TopEarnerStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String) -> TopEarnerStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! TopEarnerStatsMapper().map(response: response)
    }

    /// Returns the TopEarnerStatsMapper output upon receiving `top-performers-day`
    ///
    func mapTopEarnerStatsWithDayUnitResponse() -> TopEarnerStats? {
        return mapStatItems(from: "top-performers-day")
    }

    /// Returns the TopEarnerStatsMapper output upon receiving `top-performers-week`
    ///
    func mapTopEarnerStatsWithWeekUnitResponse() -> TopEarnerStats? {
        return mapStatItems(from: "top-performers-week")
    }

    /// Returns the TopEarnerStatsMapper output upon receiving `top-performers-month`
    ///
    func mapTopEarnerStatsWithMonthUnitResponse() -> TopEarnerStats? {
        return mapStatItems(from: "top-performers-month")
    }

    /// Returns the TopEarnerStatsMapper output upon receiving `top-performers-year`
    ///
    func mapTopEarnerStatsWithYearUnitResponse() -> TopEarnerStats? {
        return mapStatItems(from: "top-performers-year")
    }
}
