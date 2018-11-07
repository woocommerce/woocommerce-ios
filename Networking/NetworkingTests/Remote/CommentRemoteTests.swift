import XCTest
@testable import Networking


/// CommentRemote Unit Tests
///
class CommentRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Order ID
    ///
    let sampleCommentID = 2

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadAccountDetails properly parses the `me` sample response.
    ///
    func testMarkCommentAsSpamReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Load Account Details")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-spam")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .spam) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .spam)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
