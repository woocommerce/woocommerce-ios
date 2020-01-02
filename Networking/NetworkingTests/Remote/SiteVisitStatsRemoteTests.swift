import XCTest
@testable import Networking


/// SiteVisitStatsRemote Unit Tests
///
class SiteVisitStatsRemoteTests: XCTestCase {

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


    /// Verifies that loadSiteVisitorStats properly parses the `SiteVisitStats` sample response.
    ///
    func testLoadSiteVisitStatsProperlyReturnsParsedStats() {
        let remote = SiteVisitStatsRemote(network: network)
        let expectation = self.expectation(description: "Load order stats")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-day")
        remote.loadSiteVisitorStats(for: sampleSiteID, unit: .day, latestDateToInclude: Date(), quantity: 12) { (siteVisitStats, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteVisitStats)
            XCTAssertEqual(siteVisitStats?.items?.count, 12)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadSiteVisitorStats properly relays Networking Layer errors.
    ///
    func testLoadSiteVisitStatsProperlyRelaysNetwokingErrors() {
        let remote = SiteVisitStatsRemote(network: network)
        let expectation = self.expectation(description: "Load order stats contains errors")

        remote.loadSiteVisitorStats(for: sampleSiteID, unit: .day, latestDateToInclude: Date(), quantity: 12) { (siteVisitStats, error) in
            XCTAssertNil(siteVisitStats)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
