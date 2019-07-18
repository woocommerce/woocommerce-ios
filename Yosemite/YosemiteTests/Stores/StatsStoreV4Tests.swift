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

    /// Verifies that `StatsAction.retrieveStats` effectively persists any retrieved OrderStatsV4.
    ///
    func testRetrieveStatsEffectivelyPersistsRetrievedStats() {
        let expectation = self.expectation(description: "Persist order stats")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-year")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsV4.self), 0)

        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID, granularity: .yearly,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
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

    /// Verifies that `StatsAction.retrieveStats` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order stats error response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "generic_error")
        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID, granularity: .yearly,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `StatsAction.retrieveStats` returns an error whenever there is no backend response.
    ///
    func testRetrieveStatsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve site visit stats empty response")
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = StatsActionV4.retrieveStats(siteID: sampleSiteID, granularity: .yearly,
                                                    latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (error) in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        statsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Misc

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}


// MARK: - Private Methods
//
private extension StatsStoreV4Tests {

    // MARK: - Order Stats V4 Sample

    func sampleStats() -> Networking.OrderStatsV4 {
        return OrderStatsV4(siteID: sampleSiteID,
                            granularity: .yearly,
                            totals: sampleTotals(),
                            intervals: sampleIntervals())
    }

    func sampleTotals() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 0,
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

    func sampleIntervals() -> [Networking.OrderStatsV4Interval] {
        return [sampleIntervalYear()]
    }

    func sampleIntervalYear() -> Networking.OrderStatsV4Interval {
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
}
