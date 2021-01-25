import XCTest
@testable import Networking


/// SiteVisitStatsMapper Unit Tests
///
class SiteVisitStatsMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 16

    /// Verifies that all of the day unit SiteVisitStats fields are parsed correctly.
    ///
    func test_day_unit_stat_fields_are_properly_parsed() {
        guard let dayStats = mapSiteVisitStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.siteID, sampleSiteID)
        XCTAssertEqual(dayStats.granularity, .day)
        XCTAssertEqual(dayStats.date, "2018-08-06")
        XCTAssertEqual(dayStats.items!.count, 12)
        XCTAssertEqual(dayStats.totalVisitors, 105)

        let sampleItem1 = dayStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018-07-26")
        XCTAssertEqual(sampleItem1.visitors, 101)

        let sampleItem2 = dayStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018-08-06")
        XCTAssertEqual(sampleItem2.visitors, 2)
    }

    /// Verifies that all of the week unit SiteVisitStats fields are parsed correctly.
    ///
    func test_week_unit_stat_fields_are_properly_parsed() {
        guard let weekStats = mapSiteVisitStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.siteID, sampleSiteID)
        XCTAssertEqual(weekStats.granularity, .week)
        XCTAssertEqual(weekStats.date, "2018-08-06")
        XCTAssertEqual(weekStats.items!.count, 12)
        XCTAssertEqual(weekStats.totalVisitors, 123123241)

        let sampleItem1 = weekStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018W05W21")
        XCTAssertEqual(sampleItem1.visitors, 4)

        let sampleItem2 = weekStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018W08W06")
        XCTAssertEqual(sampleItem2.visitors, 123123123)
    }

    /// Verifies that all of the month unit SiteVisitStats fields are parsed correctly.
    ///
    func test_month_unit_stat_fields_are_properly_parsed() {
        guard let monthStats = mapSiteVisitStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.siteID, sampleSiteID)
        XCTAssertEqual(monthStats.granularity, .month)
        XCTAssertEqual(monthStats.date, "2018-08-06")
        XCTAssertEqual(monthStats.items!.count, 12)
        XCTAssertEqual(monthStats.totalVisitors, 292)

        let sampleItem1 = monthStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2017-09-01")
        XCTAssertEqual(sampleItem1.visitors, 224)

        let sampleItem2 = monthStats.items![10]
        XCTAssertEqual(sampleItem2.period, "2018-07-01")
        XCTAssertEqual(sampleItem2.visitors, 6)
    }

    /// Verifies that all of the year unit SiteVisitStats fields are parsed correctly.
    ///
    func test_year_unit_stat_fields_are_properly_parsed() {
        guard let yearStats = mapSiteVisitStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.siteID, sampleSiteID)
        XCTAssertEqual(yearStats.granularity, .year)
        XCTAssertEqual(yearStats.date, "2018-08-06")
        XCTAssertEqual(yearStats.items!.count, 5)
        XCTAssertEqual(yearStats.totalVisitors, 3336)

        let sampleItem1 = yearStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2014-01-01")
        XCTAssertEqual(sampleItem1.visitors, 1145)

        let sampleItem2 = yearStats.items![3]
        XCTAssertEqual(sampleItem2.period, "2017-01-01")
        XCTAssertEqual(sampleItem2.visitors, 144)
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

        return try! SiteVisitStatsMapper(siteID: sampleSiteID).map(response: response)
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
