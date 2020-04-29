import XCTest
@testable import Networking


/// SitePostsRemote Unit Tests
///
class SitePostsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 3584907

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load Site Posts tests

    /// Verifies that 'loadSitePost' properly parses the successful response
    ///
    func testLoadSitePostProperlyReturnsSuccess() {
        let remote = SitePostsRemote(network: network)
        let expectation = self.expectation(description: "Load site post")

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "site-post")
        remote.loadSitePost(for: sampleSiteID, postID: 7) {[weak self] (sitePost, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(sitePost)
            XCTAssertEqual(sitePost?.siteID, self?.sampleSiteID)
            XCTAssertEqual(sitePost?.password, "woooooooo!")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'loadSitePost' properly relays Networking Layer errors.
    ///
    func testSearchSkuProperlyRelaysNetwokingErrors() {
        let remote = SitePostsRemote(network: network)
        let expectation = self.expectation(description: "Wait for a site post result")

        remote.loadSitePost(for: sampleSiteID, postID: 7) { (sitePost, error) in
            XCTAssertNil(sitePost)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}
