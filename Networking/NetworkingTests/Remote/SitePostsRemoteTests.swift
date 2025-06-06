import XCTest
@testable import Networking


/// SitePostsRemote Unit Tests
///
class SitePostsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

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
    func test_load_site_post_properly_returns_parsed_post() async throws {
        // Given
        let remote = SitePostsRemote(network: network)
        let postID: Int64 = 7
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/posts/\(postID)", filename: "site-post")

        // When
        let sitePost = try await remote.loadSitePost(for: sampleSiteID, postID: postID)

        // Then
        XCTAssertEqual(sitePost.siteID, sampleSiteID)
        XCTAssertEqual(sitePost.password, "woooooooo!")
    }

    /// Verifies that 'loadSitePost' properly relays Networking Layer errors.
    ///
    func test_load_site_post_relays_networking_errors() async {
        // Given
        let remote = SitePostsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.loadSitePost(for: sampleSiteID, postID: 7)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
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
