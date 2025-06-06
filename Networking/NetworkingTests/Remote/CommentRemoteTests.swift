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
    func testModerateCommentAsSpamProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-spam-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .spam)

        // Then
        XCTAssertEqual(updatedStatus, .spam)
    }

    /// Verifies that 'moderateComment' as unspam properly parses the successful response
    ///
    func testModerateCommentAsUnspamProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-unspam-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .unspam)

        // Then
        XCTAssertEqual(updatedStatus, .unspam)
    }

    /// Verifies that 'moderateComment' as approved properly parses the successful response
    ///
    func testModerateCommentAsApprovedProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .approved)

        // Then
        XCTAssertEqual(updatedStatus, .approved)
    }

    /// Verifies that 'moderateComment' as unapproved properly parses the successful response
    ///
    func testModerateCommentAsUnapprovedProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-unapproved-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .unapproved)

        // Then
        XCTAssertEqual(updatedStatus, .unapproved)
    }

    /// Verifies that 'moderateComment' as trash properly parses the successful response
    ///
    func testModerateCommentAsTrashProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-trash-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .trash)

        // Then
        XCTAssertEqual(updatedStatus, .trash)
    }

    /// Verifies that 'moderateComment' as untrash properly parses the successful response
    ///
    func testModerateCommentAsUntrashProperlyParsesSuccessfulResponse() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-untrash-success")

        // When
        let updatedStatus = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .untrash)

        // Then
        XCTAssertEqual(updatedStatus, .untrash)
    }

    /// Verifies that `moderateComment` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testModerateCommentProperlyParsesErrorResponse() async {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "generic_error")

        // When
        do {
            _ = try await remote.moderateComment(siteID: sampleSiteID, commentID: sampleCommentID, status: .untrash)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is DotcomError)
        }
    }

    func test_replyToComment_returns_parsed_status_for_comment_reply() async throws {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments", filename: "comment-moderate-approved")

        // When
        let commentStatus = try await remote.replyToComment(siteID: sampleSiteID, 
                                                          commentID: sampleCommentID, 
                                                          productID: 1234, 
                                                          content: "Sample comment")

        // Then
        XCTAssertEqual(commentStatus, .approved)
    }

    func test_replyToComment_properly_parses_error_responses() async {
        // Given
        let remote = CommentRemote(network: network)
        network.simulateError(requestUrlSuffix: "sites/\(sampleSiteID)/comments", error: NetworkError.timeout())

        // When
        do {
            _ = try await remote.replyToComment(siteID: sampleSiteID, 
                                              commentID: sampleCommentID, 
                                              productID: 1234, 
                                              content: "Sample comment")
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is NetworkError)
        }
    }
}
