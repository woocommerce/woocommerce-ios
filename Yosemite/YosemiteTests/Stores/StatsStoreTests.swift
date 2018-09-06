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
    private let sampleSiteID = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    // MARK: - StatsAction.retrieveOrderStats


    /// Verifies that StatsAction.retrieveOrderStats returns the expected stats.
    ///
    func testRetrieveOrderStatsReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order stats")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrderStats = sampleOrderStats()

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "order-stats")
        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
                                                            XCTAssertNil(error)
                                                            guard let orderStats = orderStats,
                                                                let items = orderStats.items else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            XCTAssertEqual(items.count, 2)
                                                            XCTAssertEqual(orderStats, remoteOrderStats)
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveOrderStats returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order stats error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "generic_error")
        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
                                                            XCTAssertNil(orderStats)
                                                            XCTAssertNotNil(error)
                                                            guard let _ = error else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveOrderStats returns an error whenever there is no backend response.
    ///
    func testRetrieveOrderStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve order stats empty response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(orderStats)
            guard let _ = error else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - StatsAction.retrieveSiteVisitStats


    /// Verifies that StatsAction.retrieveSiteVisitStats returns the expected stats.
    ///
    func testRetrieveSiteVisitStatsReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve site visit stats")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteVisitStats = sampleSiteVisitStats()

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits")
        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID, granularity: .day,
                                                        latestDateToInclude: date(with: "2018-08-06T17:06:55"), quantity: 2) { (siteVisitStats, error) in
                                                        XCTAssertNil(error)
                                                        guard let siteVisitStats = siteVisitStats,
                                                            let items = siteVisitStats.items else {
                                                                XCTFail()
                                                                return
                                                        }
                                                        XCTAssertEqual(items.count, 2)
                                                        XCTAssertEqual(siteVisitStats, remoteSiteVisitStats)
                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveSiteVisitStats returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve site visit stats error response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "generic_error")
        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID, granularity: .year,
                                                        latestDateToInclude: date(with: "2015-06-23T17:06:55"), quantity: 2) { (siteVisitStats, error) in
                                                            XCTAssertNil(siteVisitStats)
                                                            XCTAssertNotNil(error)
                                                            guard let _ = error else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that StatsAction.retrieveSiteVisitStats returns an error whenever there is no backend response.
    ///
    func testRetrieveSiteVisitStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsAction.retrieveSiteVisitStats(siteID: sampleSiteID, granularity: .day,
                                                        latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (siteVisitStats, error) in
                                                            XCTAssertNotNil(error)
                                                            XCTAssertNil(siteVisitStats)
                                                            guard let _ = error else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
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
}


// MARK: - Private Methods
//
private extension StatsStoreTests {

    //  MARK: - Order Stats Sample

    func sampleOrderStats() -> OrderStats {
        return OrderStats(date: "2018-06-02",
                          granularity: .day,
                          quantity: "2",
                          fields: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                   "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                   "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
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

    func sampleOrderStatsItem1() -> OrderStatsItem {
        return OrderStatsItem(fieldNames: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                           "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                           "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
                              rawData: ["2018-06-01", 2, 2, 0, 0, 14.24, 0.12, 9.9800000000000004, 0.28000000000000003, 0, 0, 0, 0, "USD", 14.24, 14.120000000000001, 7.1200000000000001, 1])
    }

    func sampleOrderStatsItem2() -> OrderStatsItem {
        return OrderStatsItem(fieldNames: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                           "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                           "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
                              rawData: ["2018-06-02", 1, 1, 0, 0, 30.870000000000001, 0.87, 0, 0, 0, 0, 0, 0, "USD", 30.870000000000001, 30, 30.870000000000001, 1])
    }

    //  MARK: - Site Visit Stats Sample

    func sampleSiteVisitStats() -> SiteVisitStats {
        return SiteVisitStats(date: "2015-08-06",
                              granularity: .year,
                              fields: ["period", "views", "visitors", "likes", "reblogs", "comments", "posts"],
                              items: [sampleSiteVisitStatsItem1(), sampleSiteVisitStatsItem2()])
    }


    func sampleSiteVisitStatsItem1() -> SiteVisitStatsItem {
        return SiteVisitStatsItem(fieldNames: ["period", "views", "visitors", "likes", "reblogs", "comments", "posts"],
                                  rawData: ["2014-01-01", 12821, 1135, 1094, 0, 1611, 597])
    }

    func sampleSiteVisitStatsItem2() -> SiteVisitStatsItem {
        return SiteVisitStatsItem(fieldNames: ["period", "views", "visitors", "likes", "reblogs", "comments", "posts"],
                                  rawData: ["2015-01-01", 14808, 1629, 1492, 0, 1268, 571])
    }

    // MARK: - Top Earner Stats Sample

    func sampleTopEarnerStats() -> Networking.TopEarnerStats {
        return TopEarnerStats(period: "2018-W12",
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

    // MARK: - Misc

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
