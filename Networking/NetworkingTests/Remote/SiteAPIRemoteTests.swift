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
    func test_loadAPIInformation_properly_returns_parsed_settings() throws {
        // Given
        let remote = SiteAPIRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "", filename: "site-api")

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            remote.loadAPIInformation(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteAPI = try result.get()
        XCTAssertEqual(siteAPI.siteID, sampleSiteID)
        XCTAssertEqual(siteAPI.highestWooVersion, WooAPIVersion.mark3)
    }

    /// Verifies that loadAPIInformation properly relays Networking Layer errors.
    ///
    func test_loadAPIInformation_properly_relays_networking_errors() {
        // Given
        let remote = SiteAPIRemote(network: network)

        // When
        let result: Result<SiteAPI, Error> = waitFor { promise in
            remote.loadAPIInformation(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
