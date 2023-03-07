import XCTest
@testable import Networking


/// CommentRemote Unit Tests
///
class CommentRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    let sampleCommentID: Int64 = 2

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that 'moderateComment' as spam properly parses the successful response
    ///
    func testMarkCommentAsSpamReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as spam")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-spam")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .spam) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .spam)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'moderateComment' as unspam properly parses the successful response
    ///
    func testMarkCommentAsUnspamReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as unspam")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .unspam) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .approved)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'moderateComment' as approved properly parses the successful response
    ///
    func testMarkCommentAsApprovedReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as approved")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .approved) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .approved)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'moderateComment' as unapproved properly parses the successful response
    ///
    func testMarkCommentAsUnapprovedReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as unapproved")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-unapproved")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .unapproved) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .unapproved)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'moderateComment' as trash properly parses the successful response
    ///
    func testMarkCommentAsTrashReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as trash")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-trash")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .trash) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .trash)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that 'moderateComment' as untrash properly parses the successful response
    ///
    func testMarkCommentAsUntrashReturnsSuccess() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Mark comment as untrash")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .untrash) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(updatedStatus)
            XCTAssertEqual(updatedStatus, .approved)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `moderateComment` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testUpdateReadStatusProperlyParsesErrorResponses() {
        let remote = CommentRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "generic_error")
        remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .untrash) { (updatedStatus, error) in
            guard let error = error as? DotcomError else {
                XCTFail()
                return
            }

            XCTAssert(error == .unauthorized)
            XCTAssertNil(updatedStatus)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_replyToComment_returns_parsed_status_for_comment_reply() throws {
        // Given
        let remote = CommentRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments", filename: "comment-moderate-approved")

        // When
        var result: Result<CommentStatus, Error>?
        waitForExpectation { expectation in
            remote.replyToComment(siteID: sampleSiteID, commentID: sampleCommentID, productID: 1234, content: "Sample comment") { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        let commentStatus = try XCTUnwrap(result?.get())
        XCTAssertEqual(commentStatus, .approved)
    }

    func test_replyToComment_properly_parses_error_responses() throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateError(requestUrlSuffix: "sites/\(sampleSiteID)/comments", error: NetworkError.timeout)

        // When
        var result: Result<CommentStatus, Error>?
        waitForExpectation { expectation in
            remote.replyToComment(siteID: sampleSiteID, commentID: sampleCommentID, productID: 1234, content: "Sample comment") { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)
    }
}
