import XCTest
@testable import Networking


/// SiteSettingsRemote Unit Tests
///
class SiteSettingsRemoteTests: XCTestCase {

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

    /// Verifies that loadGeneralSettings properly parses the sample response.
    ///
    func testLoadGeneralSettingsProperlyReturnsParsedSettings() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load site settings")

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")
        remote.loadGeneralSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteSettings)
            XCTAssertEqual(siteSettings?.count, 20)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadGeneralSettings properly relays Networking Layer errors.
    ///
    func testLoadGeneralSettingsProperlyRelaysNetwokingErrors() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load site settings contains errors")

        remote.loadGeneralSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(siteSettings)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
