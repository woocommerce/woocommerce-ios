
import Foundation
import XCTest
import TestKit

@testable import WooCommerce

/// Test cases for `EmptyStateViewController`.
///
final class EmptyStateViewControllerTests: XCTestCase {

    func test_it_hides_all_configurable_elements_except_message_by_default() throws {
        // Given
        let viewController = EmptyStateViewController()

        // When
        _ = try XCTUnwrap(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // Then
        XCTAssertTrue(mirror.imageView.isHidden)
        XCTAssertTrue(mirror.detailsLabel.isHidden)
        XCTAssertTrue(mirror.actionButton.isHidden)

        XCTAssertNil(mirror.messageLabel.attributedText)
        XCTAssertNil(mirror.imageView.image)
        XCTAssertNil(mirror.detailsLabel.text)
        XCTAssertNil(mirror.actionButton.titleLabel?.text)
    }

    func test_given_a_simple_config_it_hides_the_details_and_action_button() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // When
        viewController.configure(.simple(message: NSAttributedString(string: "Ola"), image: .infoImage))

        // Then
        XCTAssertFalse(mirror.messageLabel.isHidden)
        XCTAssertTrue(mirror.detailsLabel.isHidden)
        XCTAssertTrue(mirror.actionButton.isHidden)

        XCTAssertEqual(mirror.messageLabel.attributedText, NSAttributedString(string: "Ola"))
        XCTAssertEqual(mirror.imageView.image, UIImage.infoImage)
    }

    func test_given_a_link_config_it_shows_all_the_elements() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // When
        viewController.configure(.withLink(
            message: NSAttributedString(string: "Ola"),
            image: .infoImage,
            details: "Dolores eum",
            linkTitle: "Bakero!",
            linkURL: WooConstants.URLs.blog.asURL()
        ))

        // Then
        XCTAssertFalse(mirror.messageLabel.isHidden)
        XCTAssertFalse(mirror.detailsLabel.isHidden)
        XCTAssertFalse(mirror.actionButton.isHidden)

        XCTAssertEqual(mirror.messageLabel.attributedText, NSAttributedString(string: "Ola"))
        XCTAssertEqual(mirror.imageView.image, UIImage.infoImage)
        XCTAssertEqual(mirror.detailsLabel.text, "Dolores eum")
        XCTAssertEqual(mirror.actionButton.titleLabel?.text, "Bakero!")
    }

    func test_the_imageView_visibility_is_set_during_configure() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // Should be hidden by default
        XCTAssertTrue(mirror.imageView.isHidden)

        // When
        viewController.configure(.simple(message: NSAttributedString(string: "Ola"), image: .infoImage))

        // Then

        // The visibility depends on the traitCollection which we don't control. If the test
        // environment is in landscape, we cannot reliably test it. So for now, we'll have
        // to define what the visibility should be.
        let shouldBeHidden = viewController.traitCollection.verticalSizeClass == .compact

        XCTAssertEqual(mirror.imageView.isHidden, shouldBeHidden)
    }

    func test_given_a_compact_verticalSizeClass_it_will_hide_the_imageView() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        viewController.configure(.simple(message: NSAttributedString(string: ""), image: .infoImage))

        // When
        viewController.willTransition(to: UITraitCollection(verticalSizeClass: .compact),
                                      with: MockViewControllerTransitionCoordinator())

        // Then
        XCTAssertTrue(mirror.imageView.isHidden)
    }

    func test_given_a_non_compact_verticalSizeClass_it_will_not_hide_the_imageView() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        viewController.configure(.simple(message: NSAttributedString(string: ""), image: .infoImage))

        // When
        viewController.willTransition(to: UITraitCollection(verticalSizeClass: .regular),
                                      with: MockViewControllerTransitionCoordinator())

        // Then
        XCTAssertFalse(mirror.imageView.isHidden)
    }

    func test_given_a_supportRequest_config_then_it_shows_all_the_elements() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // When
        viewController.configure(.withSupportRequest(
            message: NSAttributedString(string: "aTque"),
            image: .infoImage,
            details: "Sequi corrupti explicabo",
            buttonTitle: "Contact You!"
        ))

        // Then
        XCTAssertFalse(mirror.messageLabel.isHidden)
        XCTAssertFalse(mirror.detailsLabel.isHidden)
        XCTAssertFalse(mirror.actionButton.isHidden)

        XCTAssertEqual(mirror.messageLabel.attributedText, NSAttributedString(string: "aTque"))
        XCTAssertEqual(mirror.imageView.image, UIImage.infoImage)
        XCTAssertEqual(mirror.detailsLabel.text, "Sequi corrupti explicabo")
        XCTAssertEqual(mirror.actionButton.titleLabel?.text, "Contact You!")
    }

    func test_given_a_supportRequest_config_when_tapping_on_button_then_the_contact_us_page_is_presented() throws {
        // Given
        let zendeskManager = MockZendeskManager()
        let viewController = EmptyStateViewController(style: .basic, zendeskManager: zendeskManager)
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        viewController.configure(.withSupportRequest(
            message: NSAttributedString(string: ""),
            image: .infoImage,
            details: "",
            buttonTitle: "Dolores"
        ))

        assertEmpty(zendeskManager.newRequestIfPossibleInvocations)

        // When
        mirror.actionButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(zendeskManager.newRequestIfPossibleInvocations.count, 1)

        let invocation = try XCTUnwrap(zendeskManager.newRequestIfPossibleInvocations.first)
        XCTAssertEqual(invocation.controller, viewController)
        XCTAssertNil(invocation.sourceTag)
    }

    // MARK: - Pull to refresh

    func test_given_a_simple_config_with_pull_to_refresh_handler_when_pulled_to_refresh_fires_callback() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        let exp = expectation(description: "Pull to refresh callback executed.")
        let completionHandler: ((UIRefreshControl) -> Void) = { _ in
            exp.fulfill()
        }
        // When
        viewController.configure(.simple(message: NSAttributedString(string: "Ola"),
                                         image: .infoImage,
                                         onPullToRefresh: completionHandler))

        // Then
        XCTAssertNotNil(mirror.scrollView.refreshControl)

        // When
        mirror.scrollView.refreshControl?.sendActions(for: .valueChanged)

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout)
    }
}

// MARK: - Mirroring

private extension EmptyStateViewControllerTests {
    struct EmptyStateViewControllerMirror {
        let messageLabel: UILabel
        let imageView: UIImageView
        let detailsLabel: UILabel
        let actionButton: UIButton
        let scrollView: UIScrollView
    }

    func mirror(of viewController: EmptyStateViewController) throws -> EmptyStateViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)

        return EmptyStateViewControllerMirror(
            messageLabel: try XCTUnwrap(mirror.descendant("messageLabel") as? UILabel),
            imageView: try XCTUnwrap(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try XCTUnwrap(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try XCTUnwrap(mirror.descendant("actionButton") as? UIButton),
            scrollView: try XCTUnwrap(mirror.descendant("scrollView") as? UIScrollView)
        )
    }
}

// MARK: - MockViewControllerTransitionCoordinator

@objc private class MockViewControllerTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                 completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        animation?(self)
        return true
    }

    func animateAlongsideTransition(in view: UIView?,
                                    animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                                    completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        animation?(self)
        return true
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {

    }

    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {

    }

    let isAnimated: Bool = false

    let presentationStyle: UIModalPresentationStyle = .formSheet

    let initiallyInteractive: Bool = false

    let isInterruptible: Bool = false

    let isInteractive: Bool = false

    let isCancelled: Bool = false

    let transitionDuration: TimeInterval = .leastNonzeroMagnitude

    let percentComplete: CGFloat = 0

    let completionVelocity: CGFloat = 1

    let completionCurve: UIView.AnimationCurve = .easeIn

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        nil
    }

    let containerView: UIView = UIView()

    let targetTransform: CGAffineTransform = .identity
}
