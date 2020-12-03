import XCTest
@testable import Networking


/// TopEarnerStatsRemote Unit Tests
///
class TopEarnerStatsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadTopEarnersStats properly returns the `topEarnerStats` response.
    ///
    func testLoadTopEarnerStatsProperlyReturnsParsedStats() {
        let remote = TopEarnersStatsRemote(network: network)
        let expectation = self.expectation(description: "Load top earner stats")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners/", filename: "top-performers-year")
        remote.loadTopEarnersStats(for: sampleSiteID, unit: .year, latestDateToInclude: "2018", limit: 5) { (topEarnerStats, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(topEarnerStats)
            XCTAssertEqual(topEarnerStats?.items?.count, 4)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadTopEarnersStats properly relays Networking Layer errors.
    ///
    func testLoadTopEarnerStatsProperlyRelaysNetwokingErrors() {
        let remote = TopEarnersStatsRemote(network: network)
        let expectation = self.expectation(description: "Load top earner stats contains errors")

        remote.loadTopEarnersStats(for: sampleSiteID, unit: .year, latestDateToInclude: "2018", limit: 5) { (topEarnerStats, error) in
            XCTAssertNil(topEarnerStats)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
