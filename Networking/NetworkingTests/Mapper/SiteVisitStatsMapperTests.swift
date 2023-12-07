import XCTest
@testable import Networking


/// SiteVisitStatsMapper Unit Tests
///
class SiteVisitStatsMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 16

    /// Verifies that all of the day unit SiteVisitStats fields are parsed correctly.
    ///
    func test_day_unit_stat_fields_are_properly_parsed() async {
        guard let dayStats = await mapSiteVisitStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.siteID, sampleSiteID)
        XCTAssertEqual(dayStats.granularity, .day)
        XCTAssertEqual(dayStats.date, "2018-08-06")
        XCTAssertEqual(dayStats.items!.count, 12)

        let sampleItem1 = dayStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018-07-26")
        XCTAssertEqual(sampleItem1.visitors, 101)
        XCTAssertEqual(sampleItem1.views, 202)

        let sampleItem2 = dayStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018-08-06")
        XCTAssertEqual(sampleItem2.visitors, 2)
        XCTAssertEqual(sampleItem2.views, 4)
    }

    /// Verifies that all of the week unit SiteVisitStats fields are parsed correctly.
    ///
    func test_week_unit_stat_fields_are_properly_parsed() async {
        guard let weekStats = await mapSiteVisitStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.siteID, sampleSiteID)
        XCTAssertEqual(weekStats.granularity, .week)
        XCTAssertEqual(weekStats.date, "2018-08-06")
        XCTAssertEqual(weekStats.items!.count, 12)

        let sampleItem1 = weekStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018W05W21")
        XCTAssertEqual(sampleItem1.visitors, 4)
        XCTAssertEqual(sampleItem1.views, 8)

        let sampleItem2 = weekStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018W08W06")
        XCTAssertEqual(sampleItem2.visitors, 123123123)
        XCTAssertEqual(sampleItem2.views, 246246246)
    }

    /// Verifies that all of the month unit SiteVisitStats fields are parsed correctly.
    ///
    func test_month_unit_stat_fields_are_properly_parsed() async {
        guard let monthStats = await mapSiteVisitStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.siteID, sampleSiteID)
        XCTAssertEqual(monthStats.granularity, .month)
        XCTAssertEqual(monthStats.date, "2018-08-06")
        XCTAssertEqual(monthStats.items!.count, 12)

        let sampleItem1 = monthStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2017-09-01")
        XCTAssertEqual(sampleItem1.visitors, 224)
        XCTAssertEqual(sampleItem1.views, 448)

        let sampleItem2 = monthStats.items![10]
        XCTAssertEqual(sampleItem2.period, "2018-07-01")
        XCTAssertEqual(sampleItem2.visitors, 6)
        XCTAssertEqual(sampleItem2.views, 12)
    }

    /// Verifies that all of the year unit SiteVisitStats fields are parsed correctly.
    ///
    func test_year_unit_stat_fields_are_properly_parsed() async {
        guard let yearStats = await mapSiteVisitStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.siteID, sampleSiteID)
        XCTAssertEqual(yearStats.granularity, .year)
        XCTAssertEqual(yearStats.date, "2018-08-06")
        XCTAssertEqual(yearStats.items!.count, 5)

        let sampleItem1 = yearStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2014-01-01")
        XCTAssertEqual(sampleItem1.visitors, 1145)
        XCTAssertEqual(sampleItem1.views, 2290)

        let sampleItem2 = yearStats.items![3]
        XCTAssertEqual(sampleItem2.period, "2017-01-01")
        XCTAssertEqual(sampleItem2.visitors, 144)
        XCTAssertEqual(sampleItem2.views, 288)
    }
}


/// Private Methods.
///
private extension SiteVisitStatsMapperTests {

    /// Returns the SiteVisitStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSiteVisitStatItems(from filename: String) async -> SiteVisitStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! await SiteVisitStatsMapper(siteID: sampleSiteID).map(response: response)
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-day`
    ///
    func mapSiteVisitStatsWithDayUnitResponse() async -> SiteVisitStats? {
        await mapSiteVisitStatItems(from: "site-visits-day")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-week`
    ///
    func mapSiteVisitStatsWithWeekUnitResponse() async -> SiteVisitStats? {
        await mapSiteVisitStatItems(from: "site-visits-week")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-month`
    ///
    func mapSiteVisitStatsWithMonthUnitResponse() async -> SiteVisitStats? {
        await mapSiteVisitStatItems(from: "site-visits-month")
    }

    /// Returns the SiteVisitStatsMapper output upon receiving `site-visits-year`
    ///
    func mapSiteVisitStatsWithYearUnitResponse() async -> SiteVisitStats? {
        await mapSiteVisitStatItems(from: "site-visits-year")
    }
}
