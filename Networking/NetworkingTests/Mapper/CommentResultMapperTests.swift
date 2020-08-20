import XCTest
@testable import Networking


/// CommentResultMapper Unit Tests
///
class CommentResultMapperTests: XCTestCase {

    /// Verifies that the broken response causes the mapper to return an unknown status
    ///
    func test_broken_response_returns_unknown_status() {
        let commentStatus = try? mapLoadBrokenResponse()

        XCTAssertNotNil(commentStatus)
        XCTAssertEqual(commentStatus, .unknown)
    }

    /// Verifies that an approved status response is properly parsed (YAY!).
    ///
    func test_sample_approved_response_loaded() {
        let commentStatus = try? mapApprovedResponse()

        XCTAssertNotNil(commentStatus)
        XCTAssertEqual(commentStatus, .approved)
    }

    /// Verifies that an unapproved status response is properly parsed (YAY!).
    ///
    func test_sample_unapproved_response_loaded() {
        let commentStatus = try? mapUnapprovedResponse()

        XCTAssertNotNil(commentStatus)
        XCTAssertEqual(commentStatus, .unapproved)
    }

    /// Verifies that a spam status response is properly parsed (YAY!).
    ///
    func test_sample_spam_response_loaded() {
        let commentStatus = try? mapSpamResponse()

        XCTAssertNotNil(commentStatus)
        XCTAssertEqual(commentStatus, .spam)
    }

    /// Verifies that a trash status response is properly parsed (YAY!).
    ///
    func test_sample_trash_response_loaded() {
        let commentStatus = try? mapTrashResponse()

        XCTAssertNotNil(commentStatus)
        XCTAssertEqual(commentStatus, .trash)
    }
}


/// Private Methods.
///
private extension CommentResultMapperTests {

    /// Returns the CommentResultMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapCommentResult(from filename: String) throws -> CommentStatus {
        let response = Loader.contentsOf(filename)!
        let mapper = CommentResultMapper()

        return try mapper.map(response: response)
    }

    /// Returns the CommentResultMapper output upon receiving an 'approved' status from the endpoint
    ///
    func mapApprovedResponse() throws -> CommentStatus {
        return try mapCommentResult(from: "comment-moderate-approved")
    }

    /// Returns the CommentResultMapper output upon receiving an 'unapproved' status from the endpoint
    ///
    func mapUnapprovedResponse() throws -> CommentStatus {
        return try mapCommentResult(from: "comment-moderate-unapproved")
    }

    /// Returns the CommentResultMapper output upon receiving an 'spam' status from the endpoint
    ///
    func mapSpamResponse() throws -> CommentStatus {
        return try mapCommentResult(from: "comment-moderate-spam")
    }

    /// Returns the CommentResultMapper output upon receiving an 'trash' status from the endpoint
    ///
    func mapTrashResponse() throws -> CommentStatus {
        return try mapCommentResult(from: "comment-moderate-trash")
    }

    /// Returns the CommentResultMapper output upon receiving a broken response.
    ///
    func mapLoadBrokenResponse() throws -> CommentStatus {
        return try mapCommentResult(from: "generic_error")
    }
}
