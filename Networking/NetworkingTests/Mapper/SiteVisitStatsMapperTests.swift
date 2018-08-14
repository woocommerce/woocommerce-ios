import XCTest
@testable import Networking


/// SiteVisitStatsMapper Unit Tests
///
class SiteVisitStatsMapperTests: XCTestCase {

    /// Verifies that all of the day unit SiteVisitStats fields are parsed correctly.
    ///
    func testDayUnitStatFieldsAreProperlyParsed() {
        guard let dayStats = mapSiteVisitStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.granularity, .day)
        XCTAssertEqual(dayStats.date, "2018-08-06")
        XCTAssertEqual(dayStats.fields.count, 7)
        XCTAssertEqual(dayStats.items!.count, 12)
        XCTAssertEqual(dayStats.totalVisitors, 105)

        let sampleItem1 = dayStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018-07-26")
        XCTAssertEqual(sampleItem1.views, 206)
        XCTAssertEqual(sampleItem1.visitors, 101)
        XCTAssertEqual(sampleItem1.likes, 12)
        XCTAssertEqual(sampleItem1.reblogs, 2)
        XCTAssertEqual(sampleItem1.comments, 17)
        XCTAssertEqual(sampleItem1.posts, 3)

        let sampleItem2 = dayStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018-08-06")
        XCTAssertEqual(sampleItem2.views, 1)
        XCTAssertEqual(sampleItem2.visitors, 2)
        XCTAssertEqual(sampleItem2.likes, 3)
        XCTAssertEqual(sampleItem2.reblogs, 4)
        XCTAssertEqual(sampleItem2.comments, 5)
        XCTAssertEqual(sampleItem2.posts, 6)
    }

    /// Verifies that all of the week unit SiteVisitStats fields are parsed correctly.
    ///
    func testWeekUnitStatFieldsAreProperlyParsed() {
        guard let weekStats = mapSiteVisitStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.granularity, .week)
        XCTAssertEqual(weekStats.date, "2018-08-06")
        XCTAssertEqual(weekStats.fields.count, 7)
        XCTAssertEqual(weekStats.items!.count, 12)
        XCTAssertEqual(weekStats.totalVisitors, 123123241)

        let sampleItem1 = weekStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018W05W21")
        XCTAssertEqual(sampleItem1.views, 5)
        XCTAssertEqual(sampleItem1.visitors, 4)
        XCTAssertEqual(sampleItem1.likes, 0)
        XCTAssertEqual(sampleItem1.reblogs, 0)
        XCTAssertEqual(sampleItem1.comments, 0)
        XCTAssertEqual(sampleItem1.posts, 0)

        let sampleItem2 = weekStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018W08W06")
        XCTAssertEqual(sampleItem2.views, 33)
        XCTAssertEqual(sampleItem2.visitors, 123123123)
        XCTAssertEqual(sampleItem2.likes, 1)
        XCTAssertEqual(sampleItem2.reblogs, 9999999)
        XCTAssertEqual(sampleItem2.comments, 123345)
        XCTAssertEqual(sampleItem2.posts, 56)

    }

    /// Verifies that all of the month unit SiteVisitStats fields are parsed correctly.
    ///
    func testMonthUnitStatFieldsAreProperlyParsed() {
        guard let monthStats = mapSiteVisitStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.granularity, .month)
        XCTAssertEqual(monthStats.date, "2018-08-06")
        XCTAssertEqual(monthStats.fields.count, 7)
        XCTAssertEqual(monthStats.items!.count, 12)
        XCTAssertEqual(monthStats.totalVisitors, 292)

        let sampleItem1 = monthStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2017-09-01")
        XCTAssertEqual(sampleItem1.views, 36)
        XCTAssertEqual(sampleItem1.visitors, 224)
        XCTAssertEqual(sampleItem1.likes, 1)
        XCTAssertEqual(sampleItem1.reblogs, 0)
        XCTAssertEqual(sampleItem1.comments, 3)
        XCTAssertEqual(sampleItem1.posts, 2)

        let sampleItem2 = monthStats.items![10]
        XCTAssertEqual(sampleItem2.period, "2018-07-01")
        XCTAssertEqual(sampleItem2.views, 16)
        XCTAssertEqual(sampleItem2.visitors, 6)
        XCTAssertEqual(sampleItem2.likes, 9)
        XCTAssertEqual(sampleItem2.reblogs, 0)
        XCTAssertEqual(sampleItem2.comments, 0)
        XCTAssertEqual(sampleItem2.posts, 0)
    }

    /// Verifies that all of the year unit SiteVisitStats fields are parsed correctly.
    ///
    func testYearUnitStatFieldsAreProperlyParsed() {
        guard let yearStats = mapSiteVisitStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.granularity, .year)
        XCTAssertEqual(yearStats.date, "2018-08-06")
        XCTAssertEqual(yearStats.fields.count, 7)
        XCTAssertEqual(yearStats.items!.count, 5)
        XCTAssertEqual(yearStats.totalVisitors, 3336)

        let sampleItem1 = yearStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2014-01-01")
        XCTAssertEqual(sampleItem1.views, 12821)
        XCTAssertEqual(sampleItem1.visitors, 1145)
        XCTAssertEqual(sampleItem1.likes, 1094)
        XCTAssertEqual(sampleItem1.reblogs, 0)
        XCTAssertEqual(sampleItem1.comments, 1611)
        XCTAssertEqual(sampleItem1.posts, 597)


        let sampleItem2 = yearStats.items![3]
        XCTAssertEqual(sampleItem2.period, "2017-01-01")
        XCTAssertEqual(sampleItem2.views, 348)
        XCTAssertEqual(sampleItem2.visitors, 144)
        XCTAssertEqual(sampleItem2.likes, 3)
        XCTAssertEqual(sampleItem2.reblogs, 0)
        XCTAssertEqual(sampleItem2.comments, 5)
        XCTAssertEqual(sampleItem2.posts, 4)
    }
}


/// Private Methods.
///
private extension SiteVisitStatsMapperTests {

    /// Returns the SiteVisitStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSiteVisitStatItems(from filename: String) -> SiteVisitStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! SiteVisitStatsMapper().map(response: response)
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-day`
    ///
    func mapSiteVisitStatsWithDayUnitResponse() -> SiteVisitStats? {
        return mapSiteVisitStatItems(from: "site-visits-day")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-week`
    ///
    func mapSiteVisitStatsWithWeekUnitResponse() -> SiteVisitStats? {
        return mapSiteVisitStatItems(from: "site-visits-week")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-month`
    ///
    func mapSiteVisitStatsWithMonthUnitResponse() -> SiteVisitStats? {
        return mapSiteVisitStatItems(from: "site-visits-month")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-year`
    ///
    func mapSiteVisitStatsWithYearUnitResponse() -> SiteVisitStats? {
        return mapSiteVisitStatItems(from: "site-visits-year")
    }
}
