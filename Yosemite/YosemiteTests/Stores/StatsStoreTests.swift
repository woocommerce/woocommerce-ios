import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// StatsStoreTests Unit Tests
///
class StatsStoreTests: XCTestCase {

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
    private let sampleSiteID: Int64 = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    // MARK: - StatsAction.retrieveOrderStats


    /// Verifies that `StatsAction.retrieveOrderStats` effectively persists any retrieved OrderStats.
    ///
    func testRetrieveOrderStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist order stats")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "order-stats")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStats.self), 0)

        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStats.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatsItem.self), 2)
            let readOnlyOrderStats = self.viewStorage.firstObject(ofType: Storage.OrderStats.self)?.toReadOnly()
            XCTAssertEqual(readOnlyOrderStats, self.sampleOrderStats())

            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveOrderStats` effectively persists any updated OrderStatsItems.
    ///
    func testRetrieveOrderStatsEffectivelyPersistsUpdatedItems() {
        let expectation = self.expectation(description: "Persist updated order stats items")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStats.self), 0)
        statsStore.upsertStoredOrderStats(readOnlyStats: sampleOrderStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatsItem.self), 2)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "order-stats-alt")
        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStats.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatsItem.self), 2)
            let readOnlyOrderStats = self.viewStorage.firstObject(ofType: Storage.OrderStats.self)?.toReadOnly()
            XCTAssertEqual(readOnlyOrderStats, self.sampleOrderStatsMutated())

            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveOrderStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order stats error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "generic_error")
        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveOrderStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveOrderStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredOrderStats` effectively inserts a new OrderStats, with the specified payload.
    ///
    func testUpsertStoredOrderStatsEffectivelyPersistsNewOrderStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrderStats = sampleOrderStats()

        XCTAssertNil(viewStorage.loadOrderStats(granularity: StatGranularity.year.rawValue))
        statsStore.upsertStoredOrderStats(readOnlyStats: remoteOrderStats)

        let storageOrderStats = viewStorage.loadOrderStats(granularity: StatGranularity.day.rawValue)
        XCTAssertEqual(storageOrderStats?.toReadOnly(), remoteOrderStats)
    }

    /// Verifies that `upsertStoredOrderStats` does not produce duplicate entries.
    ///
    func testUpdateStoredOrderStatsEffectivelyUpdatesPreexistantOrderStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.loadOrderStats(granularity: StatGranularity.day.rawValue))
        statsStore.upsertStoredOrderStats(readOnlyStats: sampleOrderStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsItem.self), 2)
        statsStore.upsertStoredOrderStats(readOnlyStats: sampleOrderStatsMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsItem.self), 2)

        let expectedOrderStats = sampleOrderStatsMutated()
        let storageOrderStats = viewStorage.loadOrderStats(granularity: StatGranularity.day.rawValue)
        XCTAssertEqual(storageOrderStats?.toReadOnly(), expectedOrderStats)
    }


    // MARK: - StatsAction.retrieveSiteVisitStats


    /// Verifies that `StatsAction.retrieveSiteVisitStats` effectively persists any retrieved SiteVisitStats.
    ///
    func testRetrieveSiteVisitStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist site visit stats")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)

        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                        granularity: .day,
                                                        latestDateToInclude: date(with: "2018-08-06T17:06:55"),
                                                        quantity: 2) { (error) in
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

    /// Verifies that `StatsAction.retrieveSiteVisitStats` effectively persists any updated SiteVisitStatsItems.
    ///
    func testRetrieveSiteVisitStatsEffectivelyPersistsUpdatedItems() {
        let expectation = self.expectation(description: "Persist updated site visit stats items")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-alt")
        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                        granularity: .year,
                                                        latestDateToInclude: date(with: "2018-08-06T17:06:55"),
                                                        quantity: 2) { (error) in
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

    /// Verifies that `StatsAction.retrieveSiteVisitStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve site visit stats error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "generic_error")
        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                        granularity: .year,
                                                        latestDateToInclude: date(with: "2018-08-06T17:06:55"),
                                                        quantity: 2) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveSiteVisitStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID,
                                                        granularity: .year,
                                                        latestDateToInclude: date(with: "2018-08-06T17:06:55"),
                                                        quantity: 2) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredSiteVisitStats` effectively inserts a new SiteVisitStats, with the specified payload.
    ///
    func testUpsertStoredSiteVisitStatsEffectivelyPersistsNewSiteVisitStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteVisitStats = sampleSiteVisitStats()

        XCTAssertNil(viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue))
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: remoteSiteVisitStats)

        let storageSiteVisitStats = viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue)
        XCTAssertEqual(storageSiteVisitStats?.toReadOnly(), remoteSiteVisitStats)
    }

    /// Verifies that `upsertStoredSiteVisitStats` does not produce duplicate entries.
    ///
    func testUpdateStoredSiteVisitStatsEffectivelyUpdatesPreexistantSiteVisitStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

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


    // MARK: - StatsAction.retrieveTopEarnerStats


    /// Verifies that `StatsAction.retrieveTopEarnerStats` effectively persists any retrieved TopEarnerStats.
    ///
    func testRetrieveTopEarnersStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist top earner stats")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners/", filename: "top-performers-week")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 0)

        let action = StatsAction.retrieveTopEarnerStats(siteID: sampleSiteID, granularity: .week, latestDateToInclude: Date()) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 3)
            let readOnlyTopEarnerStats = self.viewStorage.firstObject(ofType: Storage.TopEarnerStats.self)?.toReadOnly()
            XCTAssertEqual(readOnlyTopEarnerStats, self.sampleTopEarnerStats())

            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveTopEarnerStats` effectively persists any updated TopEarnerStatsItems.
    ///
    func testRetrieveTopEarnersStatsEffectivelyPersistsUpdatedItems() {
        let expectation = self.expectation(description: "Persist updated top earner stats items")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 0)
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 3)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners/", filename: "top-performers-week-alt")
        let action = StatsAction.retrieveTopEarnerStats(siteID: sampleSiteID, granularity: .week, latestDateToInclude: Date()) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)
            let readOnlyTopEarnerStats = self.viewStorage.firstObject(ofType: Storage.TopEarnerStats.self)?.toReadOnly()
            XCTAssertEqual(readOnlyTopEarnerStats, self.sampleTopEarnerStatsMutated())

            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveTopEarnerStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveTopEarnersStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve top earner stats error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners/", filename: "generic_error")
        let action = StatsAction.retrieveTopEarnerStats(siteID: sampleSiteID, granularity: .week, latestDateToInclude: Date()) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveTopEarnerStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveTopEarnersStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve top earner stats empty response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveTopEarnerStats(siteID: sampleSiteID, granularity: .week, latestDateToInclude: Date()) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredTopEarnerStats` effectively inserts a new TopEarnerStats, with the specified payload.
    ///
    func testUpsertStoredTopEarnersStatsEffectivelyPersistsNewTopEarnersStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteTopEarnersStats = sampleTopEarnerStats()

        XCTAssertNil(viewStorage.loadTopEarnerStats(date: "2018-W12", granularity: StatGranularity.week.rawValue))
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: remoteTopEarnersStats)

        let storageTopEarnersStats = viewStorage.loadTopEarnerStats(date: "2018-W12", granularity: StatGranularity.week.rawValue)
        XCTAssertEqual(storageTopEarnersStats?.toReadOnly(), remoteTopEarnersStats)
    }

    /// Verifies that `upsertStoredTopEarnerStats` does not produce duplicate entries.
    ///
    func testUpdateStoredTopEarnersStatsEffectivelyUpdatesPreexistantTopEarnersStats() {
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.loadTopEarnerStats(date: "2018-W12", granularity: StatGranularity.week.rawValue))
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 3)
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStatsMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)

        let expectedTopEarnerStats = sampleTopEarnerStatsMutated()
        let storageTopEarnerStats = viewStorage.loadTopEarnerStats(date: "2018-W12", granularity: StatGranularity.week.rawValue)
        XCTAssertEqual(storageTopEarnerStats?.toReadOnly(), expectedTopEarnerStats)
    }


    // MARK: - StatsAction.retrieveOrderTotals


    /// Verifies that StatsAction.retrieveOrderTotals returns the expected totals.
    ///
    func testRetrieveOrderTotalsReturnsExpectedTotal() {
        let expectation = self.expectation(description: "Retrieve order totals")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        let action = StatsAction.retrieveOrderTotals(siteID: sampleSiteID, status: .processing) { (total, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(total)
            XCTAssertEqual(total, 4)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveOrderTotals returns an error, whenever there is an error response.
    ///
    func testRetrieveOrderTotalsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order totals error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")
        let action = StatsAction.retrieveOrderTotals(siteID: sampleSiteID, status: .processing) { (total, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(total)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveOrderTotals returns an error, whenever there is not backend response.
    ///
    func testRetrieveOrderTotalsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve order totals empty response error")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveOrderTotals(siteID: sampleSiteID, status: .processing) { (total, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(total)
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension StatsStoreTests {

    // MARK: - Order Stats Sample

    func sampleOrderStats() -> Networking.OrderStats {
        return OrderStats(date: "2018-06-02",
                          granularity: .day,
                          quantity: "2",
                          items: [sampleOrderStatsItem1(), sampleOrderStatsItem2()],
                          totalGrossSales: 439.23,
                          totalNetSales: 438.24,
                          totalOrders: 9,
                          totalProducts: 13,
                          averageGrossSales: 14.1687,
                          averageNetSales: 14.1368,
                          averageOrders: 0.2903,
                          averageProducts: 0.4194)
    }

    func sampleOrderStatsItem1() -> Networking.OrderStatsItem {
        return OrderStatsItem(period: "2018-06-01",
                              orders: 2,
                              products: 2,
                              coupons: 0,
                              couponDiscount: 0,
                              totalSales: 14.24,
                              totalTax: 0.12,
                              totalShipping: 9.9800000000000004,
                              totalShippingTax: 0.28000000000000003,
                              totalRefund: 0,
                              totalTaxRefund: 0,
                              totalShippingRefund: 0,
                              totalShippingTaxRefund: 0,
                              currency: "USD",
                              grossSales: 14.24,
                              netSales: 14.120000000000001,
                              avgOrderValue: 7.1200000000000001,
                              avgProductsPerOrder: 1)
    }

    func sampleOrderStatsItem2() -> Networking.OrderStatsItem {
        return OrderStatsItem(period: "2018-06-02",
                              orders: 1,
                              products: 1,
                              coupons: 0,
                              couponDiscount: 0,
                              totalSales: 30.870000000000001,
                              totalTax: 0.87,
                              totalShipping: 0,
                              totalShippingTax: 0,
                              totalRefund: 0,
                              totalTaxRefund: 0,
                              totalShippingRefund: 0,
                              totalShippingTaxRefund: 0,
                              currency: "USD",
                              grossSales: 30.870000000000001,
                              netSales: 30,
                              avgOrderValue: 30.870000000000001,
                              avgProductsPerOrder: 1)
    }

    func sampleOrderStatsMutated() -> Networking.OrderStats {
        return OrderStats(date: "2018-06-02",
                          granularity: .day,
                          quantity: "2",
                          items: [sampleOrderStatsItem1Mutated(), sampleOrderStatsItem2Mutated()],
                          totalGrossSales: 539.23,
                          totalNetSales: 538.24,
                          totalOrders: 19,
                          totalProducts: 23,
                          averageGrossSales: 24.1687,
                          averageNetSales: 24.1368,
                          averageOrders: 1.2903,
                          averageProducts: 1.4194)
    }

    func sampleOrderStatsItem1Mutated() -> Networking.OrderStatsItem {
        return OrderStatsItem(period: "2018-06-01",
                              orders: 5,
                              products: 5,
                              coupons: 0,
                              couponDiscount: 0,
                              totalSales: 24.24,
                              totalTax: 1.12,
                              totalShipping: 19.98,
                              totalShippingTax: 1.28,
                              totalRefund: 0,
                              totalTaxRefund: 0,
                              totalShippingRefund: 0,
                              totalShippingTaxRefund: 0,
                              currency: "USD",
                              grossSales: 24.24,
                              netSales: 24.120000000000001,
                              avgOrderValue: 17.12,
                              avgProductsPerOrder: 11)
    }

    func sampleOrderStatsItem2Mutated() -> Networking.OrderStatsItem {
        return OrderStatsItem(period: "2018-06-02",
                              orders: 11,
                              products: 11,
                              coupons: 1,
                              couponDiscount: 1,
                              totalSales: 40.87,
                              totalTax: 1.87,
                              totalShipping: 0,
                              totalShippingTax: 0,
                              totalRefund: 0,
                              totalTaxRefund: 0,
                              totalShippingRefund: 0,
                              totalShippingTaxRefund: 0,
                              currency: "USD",
                              grossSales: 40.87,
                              netSales: 40,
                              avgOrderValue: 40.87,
                              avgProductsPerOrder: 10)
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

    // MARK: - Top Earner Stats Sample

    func sampleTopEarnerStats() -> Networking.TopEarnerStats {
        return TopEarnerStats(date: "2018-W12",
                              granularity: .week,
                              limit: "5",
                              items: [sampleTopEarnerStatsItem1(), sampleTopEarnerStatsItem2(), sampleTopEarnerStatsItem3()])
    }

    func sampleTopEarnerStatsItem1() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 296,
                                  productName: "Funky Hoodie",
                                  quantity: 1,
                                  price: 40,
                                  total: 0,
                                  currency: "USD",
                                  imageUrl: "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/05/hoodie-with-logo.jpg?w=801")
    }

    func sampleTopEarnerStatsItem2() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 373,
                                  productName: "Black Dress (H&M)",
                                  quantity: 4,
                                  price: 30,
                                  total: 120,
                                  currency: "USD",
                                  imageUrl: "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/07/hm-black.jpg?w=640")
    }

    func sampleTopEarnerStatsItem3() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 1033,
                                  productName: "Smile T-Shirt",
                                  quantity: 2,
                                  price: 80,
                                  total: 160,
                                  currency: "USD",
                                  imageUrl: "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2018/04/smile.gif?w=480")
    }

    func sampleTopEarnerStatsMutated() -> Networking.TopEarnerStats {
        return TopEarnerStats(date: "2018-W12",
                              granularity: .week,
                              limit: "4",
                              items: [sampleTopEarnerStatsMutatedItem1(), sampleTopEarnerStatsMutatedItem2()])
    }

    func sampleTopEarnerStatsMutatedItem1() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 996,
                                  productName: "Funky Hoodie 2",
                                  quantity: 444,
                                  price: 40,
                                  total: 2,
                                  currency: "USD",
                                  imageUrl: "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2017/05/hoodie-with-logo.jpg")
    }

    func sampleTopEarnerStatsMutatedItem2() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 933,
                                  productName: "Smile T-Shirt 2",
                                  quantity: 555,
                                  price: 55.44,
                                  total: 161.00,
                                  currency: "USD",
                                  imageUrl: "https://jamosova3.mystagingwebsite.com/wp-content/uploads/2018/04/smile.gif")
    }

    // MARK: - Misc

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
