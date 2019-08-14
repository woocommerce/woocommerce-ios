import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// StatsStoreV4Tests Unit Tests
///
final class StatsStoreV4Tests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: - StatsActionV4.retrieveStats

    /// Verifies that `StatsActionV4.retrieveStats` effectively persists any retrieved OrderStatsV4.
    ///
    func testRetrieveStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist order stats")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-year")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsV4.self), 0)

        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID,
                                                 timeRange: .thisYear,
                                                 earliestDateToInclude: date(with: "2018-06-23T17:06:55"),
                                                 latestDateToInclude: date(with: "2018-06-23T17:06:55"),
                                                 quantity: 2) { (error) in
                                                        XCTAssertNil(error)
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatsV4.self), 1)
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatsV4Interval.self), 1)
                                                        let readOnlyOrderStats = self.viewStorage.firstObject(ofType: Storage.OrderStatsV4.self)?.toReadOnly()
                                                        XCTAssertEqual(readOnlyOrderStats, self.sampleStats())

                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsActionV4.retrieveStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order stats error response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "generic_error")
        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID,
                                                 timeRange: .thisYear,
                                                 earliestDateToInclude: date(with: "2018-06-23T17:06:55"),
                                                 latestDateToInclude: date(with: "2018-06-23T17:06:55"),
                                                 quantity: 2) { (error) in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsActionV4.retrieveStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID, timeRange: .thisYear,
                                                 earliestDateToInclude: date(with: "2018-06-23T17:06:55"),

                                                 latestDateToInclude: date(with: "2018-06-23T17:06:55"),
                                                 quantity: 2) { (error) in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - StatsActionV4.retrieveSiteVisitStats


    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` effectively persists any retrieved SiteVisitStats.
    ///
    func testRetrieveSiteVisitStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist site visit stats")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)

        let action = StatsActionV4
            .retrieveSiteVisitStats(siteID: sampleSiteID,
                                    timeRange: .thisWeek,
                                    latestDateToInclude: date(with: "2018-08-06T17:06:55")) { (error) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
                                        let readOnlySiteVisitStats = self.viewStorage.firstObject(ofType: Storage.SiteVisitStats.self)?.toReadOnly()
                                        XCTAssertEqual(readOnlySiteVisitStats, self.sampleSiteVisitStats())

                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` effectively persists any updated SiteVisitStatsItems.
    ///
    func testRetrieveSiteVisitStatsEffectivelyPersistsUpdatedItems() {
        let expectation = self.expectation(description: "Persist updated site visit stats items")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-alt")
        let action = StatsActionV4
            .retrieveSiteVisitStats(siteID: sampleSiteID,
                                    timeRange: .thisYear,
                                    latestDateToInclude: date(with: "2018-08-06T17:06:55")) { (error) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
                                        let readOnlySiteVisitStats = self.viewStorage.firstObject(ofType: Storage.SiteVisitStats.self)?.toReadOnly()
                                        XCTAssertEqual(readOnlySiteVisitStats, self.sampleSiteVisitStatsMutated())

                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve site visit stats error response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "generic_error")
        let action = StatsActionV4.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                          timeRange: .thisYear,
                                                          latestDateToInclude: date(with: "2018-08-06T17:06:55")) { (error) in
                                                            XCTAssertNotNil(error)
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsActionV4.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                          timeRange: .thisYear,
                                                          latestDateToInclude: date(with: "2018-08-06T17:06:55")) { (error) in
                                                            XCTAssertNotNil(error)
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredSiteVisitStats` effectively inserts a new SiteVisitStats, with the specified payload.
    ///
    func testUpsertStoredSiteVisitStatsEffectivelyPersistsNewSiteVisitStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteVisitStats = sampleSiteVisitStats()

        XCTAssertNil(viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue))
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: remoteSiteVisitStats)

        let storageSiteVisitStats = viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue)
        XCTAssertEqual(storageSiteVisitStats?.toReadOnly(), remoteSiteVisitStats)
    }

    /// Verifies that `upsertStoredSiteVisitStats` does not produce duplicate entries.
    ///
    func testUpdateStoredSiteVisitStatsEffectivelyUpdatesPreexistantSiteVisitStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue))
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStatsMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)

        let expectedSiteVisitStats = sampleSiteVisitStatsMutated()
        let storageSiteVisitStats = viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue)
        XCTAssertEqual(storageSiteVisitStats?.toReadOnly(), expectedSiteVisitStats)
    }
}


// MARK: - Private Methods
//
private extension StatsStoreV4Tests {
    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

    // MARK: - Order Stats V4 Sample

    func sampleStats() -> Networking.OrderStatsV4 {
        return OrderStatsV4(siteID: sampleSiteID,
                            granularity: .monthly,
                            totals: sampleTotals(),
                            intervals: sampleIntervals())
    }


    /// Matches `totals` field in `order-stats-v4-year` response.
    func sampleTotals() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 3,
                                  totalItemsSold: 5,
                                  grossRevenue: 800,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 800,
                                  totalProducts: 0)
    }

    func sampleIntervals() -> [Networking.OrderStatsV4Interval] {
        return [sampleIntervalMonthly()]
    }

    func sampleIntervalMonthly() -> Networking.OrderStatsV4Interval {
        return OrderStatsV4Interval(interval: "2019",
                                    dateStart: "2019-07-09 00:00:00",
                                    dateEnd: "2019-07-09 23:59:59",
                                    subtotals: sampleTotals())
    }

    func sampleStatsMutated() -> Networking.OrderStatsV4 {
        return OrderStatsV4(siteID: sampleSiteID,
                            granularity: .yearly,
                            totals: sampleTotalsMutated(),
                            intervals: sampleIntervalsMutated())
    }

    func sampleIntervalsMutated() -> [Networking.OrderStatsV4Interval] {
        return [sampleIntervalYearMutated()]
    }

    func sampleIntervalYearMutated() -> Networking.OrderStatsV4Interval {
        return OrderStatsV4Interval(interval: "2019",
                                    dateStart: "2019-07-09 00:00:00",
                                    dateEnd: "2019-07-09 23:59:59",
                                    subtotals: sampleTotalsMutated())
    }

    func sampleTotalsMutated() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 10,
                                  totalItemsSold: 0,
                                  grossRevenue: 0,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 0,
                                  totalProducts: 0)
    }

    // MARK: - Site Visit Stats Sample

    func sampleSiteVisitStats() -> Networking.SiteVisitStats {
        return SiteVisitStats(date: "2015-08-06",
                              granularity: .year,
                              items: [sampleSiteVisitStatsItem1(), sampleSiteVisitStatsItem2()])
    }


    func sampleSiteVisitStatsItem1() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2014-01-01", visitors: 1135)
    }

    func sampleSiteVisitStatsItem2() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2015-01-01", visitors: 1629)
    }

    func sampleSiteVisitStatsMutated() -> Networking.SiteVisitStats {
        return SiteVisitStats(date: "2015-08-06",
                              granularity: .year,
                              items: [sampleSiteVisitStatsItem1Mutated(), sampleSiteVisitStatsItem2Mutated()])
    }


    func sampleSiteVisitStatsItem1Mutated() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2014-01-01", visitors: 1140)
    }

    func sampleSiteVisitStatsItem2Mutated() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2015-01-01", visitors: 1634)
    }
}
