import XCTest
@testable import Networking

final class OrderStatsRemoteV4Tests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that loadOrderStats properly parses the `OrderStatsV4` sample response.
    ///
    func testLoadOrderStatsProperlyReturnsParsedStats() {
        let remote = OrderStatsRemoteV4(network: network)
        let expectation = self.expectation(description: "Load order stats")

        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-hour")

        remote.loadOrderStats(for: sampleSiteID,
                              unit: .hourly,
                              latestDateToInclude: "1955-11-05",
                              quantity: 24) { (orderStatsV4, error) in
                                XCTAssertNil(error)
                                XCTAssertNotNil(orderStatsV4)
                                XCTAssertEqual(orderStatsV4?.intervals.count, 24)
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
