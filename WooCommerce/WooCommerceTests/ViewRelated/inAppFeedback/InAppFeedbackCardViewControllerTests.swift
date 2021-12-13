import XCTest
import TestKit

@testable import WooCommerce

final class InAppFeedbackCardViewControllerTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override class func setUp() {
        super.setUp()
        MockStoreReviewController.resetInvocationState()
    }

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
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

    func test_feedbackGiven_closure_is_invoked_when_tapping_like_button() throws {
        // Given
        let viewController = InAppFeedbackCardViewController()

        // When
        var feedbackGivenInvoked = false
        viewController.onFeedbackGiven = {
            feedbackGivenInvoked = true
        }

        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)
        mirror.likeButton.sendActions(for: .touchUpInside)

        // Then
        waitUntil {
            feedbackGivenInvoked == true
        }
    }

    func test_feedbackGiven_closure_is_invoked_when_tapping_didNotLike_button() throws {
        // Given
        let viewController = InAppFeedbackCardViewController()

        // When
        var feedbackGivenInvoked = false
        viewController.onFeedbackGiven = {
            feedbackGivenInvoked = true
        }

        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)
        mirror.didNotLikeButton.sendActions(for: .touchUpInside)

        // Then
        waitUntil {
            feedbackGivenInvoked == true
        }
    }

    func test_liked_event_is_tracked_when_likeButton_is_tapped() throws {
        // Given
        let viewController = InAppFeedbackCardViewController(analytics: analytics)
        _ = try XCTUnwrap(viewController.view)

        let mirror = try self.mirror(of: viewController)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        mirror.likeButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "app_feedback_prompt")

        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["action"] as? String, "liked")
    }

    func test_didntLike_event_is_tracked_when_didNotLikeButton_is_tapped() throws {
        // Given
        let viewController = InAppFeedbackCardViewController(analytics: analytics)
        _ = try XCTUnwrap(viewController.view)

        let mirror = try self.mirror(of: viewController)

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        mirror.didNotLikeButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "app_feedback_prompt")

        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["action"] as? String, "didnt_like")
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
