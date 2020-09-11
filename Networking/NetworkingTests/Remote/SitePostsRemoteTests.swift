import XCTest
@testable import Networking


/// SitePostsRemote Unit Tests
///
class SitePostsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockupNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 3584907

    /// Dummy Post ID
    ///
    private let postID: Int64 = 7

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load Site Post tests

    /// Verifies that 'loadSitePost' properly parses the successful response
    ///
    func testLoadSitePostProperlyReturnsParsedPost() {
        let remote = SitePostsRemote(network: network)
        let expectation = self.expectation(description: "Load site post")

        let postID: Int64 = 7

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/posts/\(postID)", filename: "site-post")
        remote.loadSitePost(for: sampleSiteID, postID: postID) {[weak self] (sitePost, error) in
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
    func testLoadSitePostRelaysNetwokingErrors() {
        let remote = SitePostsRemote(network: network)
        let expectation = self.expectation(description: "Wait for a site post result")

        remote.loadSitePost(for: sampleSiteID, postID: 7) { (sitePost, error) in
            XCTAssertNil(sitePost)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - Update Site Post tests

    /// Verifies that updateSitePost properly parses the `site-post-update` sample response.
    ///
    func testUpdateSitePostProperlyReturnsParsedPost() {
        // Arrange
        let remote = SitePostsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/posts/\(postID)", filename: "site-post-update")

        // Action
        let newPassword = "new-password"
        let post = Post(siteID: sampleSiteID, password: newPassword)
        var result: Result<Post, Error>?
        waitForExpectation { expectation in
            remote.updateSitePost(for: sampleSiteID, postID: postID, post: post) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(try XCTUnwrap(result?.get().password), newPassword)
    }

    /// Verifies that updateSitePost properly relays Networking Layer errors.
    ///
    func testUpdateSitePostProperlyRelaysNetwokingErrors() {
        // Arrange
        let remote = SitePostsRemote(network: network)

        // Action
        let newPassword = "new-password"
        let post = Post(siteID: sampleSiteID, password: newPassword)
        var result: Result<Post, Error>?
        waitForExpectation { expectation in
            remote.updateSitePost(for: sampleSiteID, postID: postID, post: post) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(result?.isFailure, true)
    }
}
