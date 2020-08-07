import XCTest

@testable import WooCommerce

class InAppFeedbackCardViewControllerTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        MockStoreReviewController.resetInvocationState()
    }

    func test_it_presents_appStore_review_form_when_tapping_like_button() throws {
        // Given
        let viewController = InAppFeedbackCardViewController(storeReviewControllerType: MockStoreReviewController.self)

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)
        mirror.likeButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(MockStoreReviewController.requestReviewInvoked)
    }

    func test_it_doesnt_presents_appStore_review_form_when_tapping_didNotlike_button() throws {
        // Given
        let viewController = InAppFeedbackCardViewController(storeReviewControllerType: MockStoreReviewController.self)

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)
        mirror.didNotLikeButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertFalse(MockStoreReviewController.requestReviewInvoked)
    }
}

// MARK: - Mirroring
private extension InAppFeedbackCardViewControllerTests {
    struct InAppFeedbackCardViewControllerMirror {
        let likeButton: UIButton
        let didNotLikeButton: UIButton
    }

    func mirror(of viewController: InAppFeedbackCardViewController) throws -> InAppFeedbackCardViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)
        return InAppFeedbackCardViewControllerMirror(
            likeButton: try XCTUnwrap(mirror.descendant("likeButton") as? UIButton),
            didNotLikeButton: try XCTUnwrap(mirror.descendant("didNotLikeButton") as? UIButton)
        )
    }
}

private class MockStoreReviewController: SKStoreReviewControllerProtocol {

    private(set) static var requestReviewInvoked = false

    static func requestReview() {
        requestReviewInvoked = true
    }

    static func resetInvocationState() {
        requestReviewInvoked = false
    }
}
