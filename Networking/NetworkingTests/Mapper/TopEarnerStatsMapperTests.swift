import XCTest
@testable import Networking


/// TopEarnerStatsMapper Unit Tests
///
class TopEarnerStatsMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 16

    /// Verifies that all of the day unit TopEarnerStats fields are parsed correctly.
    ///
    func test_day_unit_stat_fields_are_properly_parsed() {
        guard let dayStats = mapTopEarnerStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.siteID, sampleSiteID)
        XCTAssertEqual(dayStats.granularity, .day)
        XCTAssertEqual(dayStats.date, "2018-06-08")
        XCTAssertEqual(dayStats.limit, "5")
        XCTAssertEqual(dayStats.items!.count, 1)

        let sampleItem1 = dayStats.items![0]
        XCTAssertEqual(sampleItem1.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/05/hoodie-with-logo.jpg?w=801")
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.price, 40.0)
        XCTAssertEqual(sampleItem1.productID, 296)
        XCTAssertEqual(sampleItem1.productName, "Funky Hoodie")
        XCTAssertEqual(sampleItem1.quantity, 1)
        XCTAssertEqual(sampleItem1.total, 40.0)
    }

    /// Verifies that all of the week unit TopEarnerStats fields are parsed correctly.
    ///
    func test_week_unit_stat_fields_are_properly_parsed() {
        guard let weekStats = mapTopEarnerStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.siteID, sampleSiteID)
        XCTAssertEqual(weekStats.granularity, .week)
        XCTAssertEqual(weekStats.date, "2018-W12")
        XCTAssertEqual(weekStats.limit, "5")
        XCTAssertEqual(weekStats.items!.count, 3)

        let sampleItem1 = weekStats.items![0]
        XCTAssertEqual(sampleItem1.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/05/hoodie-with-logo.jpg?w=801")
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.price, 40.0)
        XCTAssertEqual(sampleItem1.productID, 296)
        XCTAssertEqual(sampleItem1.productName, "Funky Hoodie")
        XCTAssertEqual(sampleItem1.quantity, 1)
        XCTAssertEqual(sampleItem1.total, 0.0)

        let sampleItem2 = weekStats.items![2]
        XCTAssertEqual(sampleItem2.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2018/04/smile.gif?w=480")
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.price, 80.0)
        XCTAssertEqual(sampleItem2.productID, 1033)
        XCTAssertEqual(sampleItem2.productName, "Smile T-Shirt")
        XCTAssertEqual(sampleItem2.quantity, 2)
        XCTAssertEqual(sampleItem2.total, 160.0)
    }

    /// Verifies that all of the month unit TopEarnerStats fields are parsed correctly.
    ///
    func test_month_unit_stat_fields_are_properly_parsed() {
        guard let monthStats = mapTopEarnerStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.siteID, sampleSiteID)
        XCTAssertEqual(monthStats.granularity, .month)
        XCTAssertEqual(monthStats.date, "2018-08")
        XCTAssertEqual(monthStats.limit, "5")
        XCTAssertEqual(monthStats.items!.count, 5)

        let sampleItem1 = monthStats.items![0]
        XCTAssertEqual(sampleItem1.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/08/freediving.jpg?w=768")
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.price, 249.34)
        XCTAssertEqual(sampleItem1.productID, 601)
        XCTAssertEqual(sampleItem1.productName, "Ultimate Freediving Experience")
        XCTAssertEqual(sampleItem1.quantity, 5)
        XCTAssertEqual(sampleItem1.total, 1245.0)

        let sampleItem2 = monthStats.items![3]
        XCTAssertEqual(sampleItem2.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2018/08/00030000053201_CL___JPEG_3.jpg?w=500")
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.price, 4.49)
        XCTAssertEqual(sampleItem2.productID, 1293)
        XCTAssertEqual(sampleItem2.productName, "Pancake Mix - 2lb")
        XCTAssertEqual(sampleItem2.quantity, 26)
        XCTAssertEqual(sampleItem2.total, 112.253)
    }

    /// Verifies that all of the year unit TopEarnerStats fields are parsed correctly.
    ///
    func test_year_unit_stat_fields_are_properly_parsed() {
        guard let yearStats = mapTopEarnerStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.siteID, sampleSiteID)
        XCTAssertEqual(yearStats.granularity, .year)
        XCTAssertEqual(yearStats.date, "2018")
        XCTAssertEqual(yearStats.limit, "5")
        XCTAssertEqual(yearStats.items!.count, 4)

        let sampleItem1 = yearStats.items![0]
        XCTAssertEqual(sampleItem1.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/08/freediving.jpg?w=768")
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.price, 249)
        XCTAssertEqual(sampleItem1.productID, 601)
        XCTAssertEqual(sampleItem1.productName, "Ultimate Freediving Experience")
        XCTAssertEqual(sampleItem1.quantity, 5)
        XCTAssertEqual(sampleItem1.total, 1245.0)

        let sampleItem2 = yearStats.items![1]
        XCTAssertEqual(sampleItem2.imageUrl, "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/07/hm-black.jpg?w=640")
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.price, -1234.23424)
        XCTAssertEqual(sampleItem2.productID, 373)
        XCTAssertEqual(sampleItem2.productName, "Black Dress (H&M)")
        XCTAssertEqual(sampleItem2.quantity, 1231323)
        XCTAssertEqual(sampleItem2.total, 585234234.00)
    }
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

        return try! TopEarnerStatsMapper(siteID: sampleSiteID).map(response: response)
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
