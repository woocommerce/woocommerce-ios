import XCTest
@testable import WooCommerce

class ReviewReplyViewModelTests: XCTestCase {

    func test_send_button_is_disabled_when_reply_content_is_empty() {
        // Given
        let viewModel = ReviewReplyViewModel()

        // When
        let navigationItem = viewModel.navigationTrailingItem

        // Then
        assertEqual(navigationItem, .send(enabled: false))
    }

    func test_send_button_is_enabled_when_reply_is_entered() {
        // Given
        let viewModel = ReviewReplyViewModel()

        // When
        viewModel.newReply = "New reply"

        // Then
        assertEqual(viewModel.navigationTrailingItem, .send(enabled: true))
    }
}
