import XCTest
@testable import Networking

/// SitePluginsRemote Unit Tests
///
class SitePluginsRemoteTests: XCTestCase {

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

    // MARK: - Load plugins tests

    /// Verifies that loadPlugins properly parses the sample response.
    ///
    func testLoadPluginsProperlyReturnsPlugins() {
        let remote = SitePluginsRemote(network: network)
        let expectation = self.expectation(description: "Load site plugins")

        network.simulateResponse(requestUrlSuffix: "plugins", filename: "plugins")
        remote.loadPlugins(for: sampleSiteID) { (sitePlugins, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(sitePlugins)
            XCTAssertEqual(sitePlugins?.count, 5)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadGeneralSettings properly relays Networking Layer errors.
    ///
    func testLoadPluginsProperlyRelaysNetwokingErrors() {
        let remote = SitePluginsRemote(network: network)
        let expectation = self.expectation(description: "Load site plugins handles error")

        remote.loadPlugins(for: sampleSiteID) { (sitePlugins, error) in
            XCTAssertNil(sitePlugins)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
