import XCTest
@testable import Networking


/// OrderStatsRemote Unit Tests
///
class OrderStatsRemoteTests: XCTestCase {

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


    /// Verifies that loadOrderStats properly parses the `OrderStats` sample response.
    ///
    func testLoadOrderStatsProperlyReturnsParsedStats() {
        let remote = OrderStatsRemote(network: network)
        let expectation = self.expectation(description: "Load order stats")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "order-stats-day")

        remote.loadOrderStats(for: sampleSiteID, unit: .day, latestDateToInclude: "1955-11-05", quantity: 31) { (orderStats, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderStats)
            XCTAssertEqual(orderStats?.items?.count, 31)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrderStats properly relays Networking Layer errors.
    ///
    func testLoadOrderStatsProperlyRelaysNetwokingErrors() {
        let remote = OrderStatsRemote(network: network)
        let expectation = self.expectation(description: "Load order stats contains errors")

        remote.loadOrderStats(for: sampleSiteID, unit: .day, latestDateToInclude: "1955-11-05", quantity: 31) { (orderStats, error) in
            XCTAssertNil(orderStats)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
