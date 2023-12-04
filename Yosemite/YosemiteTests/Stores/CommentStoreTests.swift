import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage



/// CommentStore Unit Tests
///
class CommentStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing CommentID
    ///
    private let sampleCommentID: Int64 = 999


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - CommentAction.updateApprovalStatus

    /// Verifies that CommentAction.updateApprovalStatus returns the expected status when approving a comment.
    ///
    func testApproveCommentReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Approve comment")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        let action = CommentAction.updateApprovalStatus(siteID: sampleSiteID, commentID: sampleCommentID, isApproved: true) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .approved)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateApprovalStatus returns the expected status when unapproving a comment.
    ///
    func testUnapproveCommentReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Unpprove comment")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-unapproved")
        let action = CommentAction.updateApprovalStatus(siteID: sampleSiteID, commentID: sampleCommentID, isApproved: false) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .unapproved)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateApprovalStatus returns an error, whenever there is an error response.
    ///
    func testUpdateApprovalStatusReturnsErrorUponReponseError() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Approve comment error response")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "generic_error")
        let action = CommentAction.updateApprovalStatus(siteID: sampleSiteID, commentID: sampleCommentID, isApproved: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateApprovalStatus returns an error, whenever there is not backend response.
    ///
    func testUpdateApprovalStatusReturnsErrorUponEmptyResponse() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Approve comment empty response error")

        let action = CommentAction.updateApprovalStatus(siteID: sampleSiteID, commentID: sampleCommentID, isApproved: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - CommentAction.updateSpamStatus

    /// Verifies that CommentAction.updateSpamStatus returns the expected status when marking a comment as spam.
    ///
    func testMarkCommentAsSpamReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as spam")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-spam")
        let action = CommentAction.updateSpamStatus(siteID: sampleSiteID, commentID: sampleCommentID, isSpam: true) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .spam)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateSpamStatus returns the expected status when marking a comment as NOT spam.
    ///
    func testMarkCommentAsNotSpamReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as not spam")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        let action = CommentAction.updateSpamStatus(siteID: sampleSiteID, commentID: sampleCommentID, isSpam: false) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .approved)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateSpamStatus returns an error, whenever there an error response.
    ///
    func testMarkCommentAsSpamReturnsErrorUponReponseError() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as spam error response")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "generic_error")
        let action = CommentAction.updateSpamStatus(siteID: sampleSiteID, commentID: sampleCommentID, isSpam: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateSpamStatus returns an error, whenever there is not backend response.
    ///
    func testMarkCommentAsSpamReturnsErrorUponEmptyResponse() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as spam empty response")

        let action = CommentAction.updateSpamStatus(siteID: sampleSiteID, commentID: sampleCommentID, isSpam: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - CommentAction.updateTrashStatus

    /// Verifies that CommentAction.updateTrashStatus returns the expected status when marking a comment as trash.
    ///
    func testMarkCommentAsTrashReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as trash")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-trash")
        let action = CommentAction.updateTrashStatus(siteID: sampleSiteID, commentID: sampleCommentID, isTrash: true) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .trash)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateTrashStatus returns the expected status when marking a comment as NOT trash.
    ///
    func testMarkCommentAsNotTrashReturnsExpectedStatus() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as not trash")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "comment-moderate-approved")
        let action = CommentAction.updateTrashStatus(siteID: sampleSiteID, commentID: sampleCommentID, isTrash: false) { (updatedStatus, error) in
            XCTAssertNil(error)
            XCTAssertEqual(updatedStatus, .approved)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateTrashStatus returns an error, whenever there an error response.
    ///
    func testMarkCommentAsTrashReturnsErrorUponReponseError() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as trash error response")

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments/\(sampleCommentID)", filename: "generic_error")
        let action = CommentAction.updateTrashStatus(siteID: sampleSiteID, commentID: sampleCommentID, isTrash: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that CommentAction.updateTrashStatus returns an error, whenever there is not backend response.
    ///
    func testMarkCommentAsTrashReturnsErrorUponEmptyResponse() {
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Mark comment as trash empty response")

        let action = CommentAction.updateTrashStatus(siteID: sampleSiteID, commentID: sampleCommentID, isTrash: true) { (updatedStatus, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(updatedStatus)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - CommentAction.replyToComment

    func test_replyToComment_returns_expected_comment_status() throws {
        // Given
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/comments", filename: "comment-moderate-approved")

        // When
        let result: Result<Yosemite.CommentStatus, Error> = waitFor { promise in
            let action = CommentAction.replyToComment(siteID: self.sampleSiteID,
                                                      commentID: self.sampleCommentID,
                                                      productID: 123,
                                                      content: "Test comment") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try XCTUnwrap(result.get()), .approved)
    }

    func test_replyToComment_returns_error_upon_response_error() {
        // Given
        let store = CommentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateError(requestUrlSuffix: "sites/\(sampleSiteID)/comments", error: NetworkError.timeout())

        // When
        let result: Result<Yosemite.CommentStatus, Error> = waitFor { promise in
            let action = CommentAction.replyToComment(siteID: self.sampleSiteID,
                                                      commentID: self.sampleCommentID,
                                                      productID: 123,
                                                      content: "Test comment") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
