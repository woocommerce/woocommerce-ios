import XCTest
@testable import Networking


/// SiteAPIRemote Unit Tests
///
class SiteAPIRemoteTests: XCTestCase {

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

    /// Verifies that loadAPIInformation properly parses the sample response.
    ///
    func testLoadGeneralSettingsProperlyReturnsParsedSettings() {
        let remote = SiteAPIRemote(network: network)
        let expectation = self.expectation(description: "Load site API information")

        network.simulateResponse(requestUrlSuffix: "", filename: "site-api")
        remote.loadAPIInformation(for: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteAPI)
            XCTAssertEqual(siteAPI?.siteID, self.sampleSiteID)
            XCTAssertEqual(siteAPI?.highestWooVersion, WooAPIVersion.mark3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAPIInformation properly relays Networking Layer errors.
    ///
    func testLoadGeneralSettingsProperlyRelaysNetworkingErrors() {
        let remote = SiteAPIRemote(network: network)
        let expectation = self.expectation(description: "Load site API information contains errors")

        remote.loadAPIInformation(for: sampleSiteID) { (siteAPI, error) in
            XCTAssertNil(siteAPI)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
