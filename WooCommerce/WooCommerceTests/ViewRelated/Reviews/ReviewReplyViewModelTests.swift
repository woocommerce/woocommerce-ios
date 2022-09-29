import XCTest
@testable import WooCommerce
@testable import Yosemite

class ReviewReplyViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

    private let sampleReviewID: Int64 = 7

    func test_send_button_is_disabled_when_reply_content_is_empty() {
        // Given
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID)

        // When
        let navigationItem = viewModel.navigationTrailingItem

        // Then
        assertEqual(navigationItem, .send(enabled: false))
    }

    func test_send_button_is_enabled_when_reply_is_entered() {
        // Given
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID)

        // When
        viewModel.newReply = "New reply"

        // Then
        assertEqual(viewModel.navigationTrailingItem, .send(enabled: true))
    }

    func test_loading_indicator_enabled_during_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID, stores: stores)
        viewModel.newReply = "New reply"

        // When
        let navigationItem: ReviewReplyNavigationItem = waitFor { promise in
            stores.whenReceivingAction(ofType: CommentAction.self) { action in
                switch action {
                case .replyToComment:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.sendReply { _ in }
        }

        // Then
        XCTAssertEqual(navigationItem, .loading)
    }

    func test_send_button_renabled_after_network_request_completes() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID, stores: stores)
        stores.whenReceivingAction(ofType: CommentAction.self) { action in
            switch action {
            case let .replyToComment(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.newReply = "New reply"
        let navigationItem: ReviewReplyNavigationItem = waitFor { promise in
            viewModel.sendReply { _ in
                promise(viewModel.navigationTrailingItem)
            }
        }

        // Then
        XCTAssertEqual(navigationItem, .send(enabled: true))
    }

    func test_sendReply_completion_block_returns_true_after_successful_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID, stores: stores)
        stores.whenReceivingAction(ofType: CommentAction.self) { action in
            switch action {
            case let .replyToComment(_, _, _, onCompletion):
                onCompletion(.success(.approved))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.newReply = "New reply"
        let successResponse: Bool = waitFor { promise in
            viewModel.sendReply { successResponse in
                promise(successResponse)
            }
        }

        // Then
        XCTAssertTrue(successResponse)
    }

    func test_sendReply_completion_block_returns_false_after_failed_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ReviewReplyViewModel(siteID: sampleSiteID, reviewID: sampleReviewID, stores: stores)
        stores.whenReceivingAction(ofType: CommentAction.self) { action in
            switch action {
            case let .replyToComment(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.newReply = "New reply"
        let successResponse: Bool = waitFor { promise in
            viewModel.sendReply { successResponse in
                promise(successResponse)
            }
        }

        // Then
        XCTAssertFalse(successResponse)
    }
}
