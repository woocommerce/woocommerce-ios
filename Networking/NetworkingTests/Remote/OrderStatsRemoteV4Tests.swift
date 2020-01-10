import XCTest
@testable import Networking

/// OrderStatsRemote Unit Tests
///
final class OrderStatsRemoteV4Tests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that loadOrderStats properly parses the `OrderStatsV4` sample response
    /// when requesting the hourly stats
    ///
    func testLoadOrderStatsProperlyReturnsParsedStatsForHourlyStats() {
        let remote = OrderStatsRemoteV4(network: network)
        let expectation = self.expectation(description: "Load order stats")

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-hour")

        remote.loadOrderStats(for: sampleSiteID,
                              unit: .hourly,
                              earliestDateToInclude: "1955-11-05",
                              latestDateToInclude: "1955-11-05",
                              quantity: 24) { (orderStatsV4, error) in
                                XCTAssertNil(error)
                                XCTAssertNotNil(orderStatsV4)
                                XCTAssertEqual(orderStatsV4?.intervals.count, 24)
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrderStats properly parses the `OrderStatsV4` sample response
    /// when requesting the weekly stats
    ///
    func testLoadOrderStatsProperlyReturnsParsedStatsForWeeklyStats() {
        let remote = OrderStatsRemoteV4(network: network)
        let expectation = self.expectation(description: "Load order stats")

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-defaults")

        remote.loadOrderStats(for: sampleSiteID,
                              unit: .weekly,
                              earliestDateToInclude: "1955-11-05",
                              latestDateToInclude: "1955-11-05",
                              quantity: 2) { (orderStatsV4, error) in
                                XCTAssertNil(error)
                                XCTAssertNotNil(orderStatsV4)
                                XCTAssertEqual(orderStatsV4?.intervals.count, 2)
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrderStats properly relays Networking Layer errors.
    ///
    func testLoadOrderStatsProperlyRelaysNetwokingErrors() {
        let remote = OrderStatsRemoteV4(network: network)
        let expectation = self.expectation(description: "Load order stats contains errors")

        remote.loadOrderStats(for: sampleSiteID,
                              unit: .daily,
                              earliestDateToInclude: "1955-11-05",
                              latestDateToInclude: "1955-11-05",
                              quantity: 31) { (orderStats, error) in
            XCTAssertNil(orderStats)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
