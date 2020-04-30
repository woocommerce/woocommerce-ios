
import Foundation
import XCTest

@testable import WooCommerce

/// Test cases for `EmptyStateViewController`.
///
final class EmptyStateViewControllerTests: XCTestCase {

    func testItHidesAllConfigurableElementsByDefault() throws {
        // Given
        let viewController = EmptyStateViewController()

        // When
        _ = try XCTUnwrap(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // Then
        XCTAssertTrue(mirror.messageLabel.isHidden)
        XCTAssertTrue(mirror.imageView.isHidden)
        XCTAssertTrue(mirror.detailsLabel.isHidden)
        XCTAssertTrue(mirror.actionButton.isHidden)

        XCTAssertNil(mirror.messageLabel.attributedText)
        XCTAssertNil(mirror.imageView.image)
        XCTAssertNil(mirror.detailsLabel.text)
        XCTAssertNil(mirror.actionButton.titleLabel?.text)
    }

    func testItShowsTheConfigurableElementsWhenProvided() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        // When
        let actionButtonConfig = EmptyStateViewController.ActionButtonConfig(title: "Bakero!") {
            // noop
        }

        viewController.configure(message: NSAttributedString(string: "Ola"),
                                 image: .appleIcon,
                                 details: "Dolores eum",
                                 actionButton: actionButtonConfig)

        // Then
        XCTAssertFalse(mirror.messageLabel.isHidden)
        XCTAssertFalse(mirror.imageView.isHidden)
        XCTAssertFalse(mirror.detailsLabel.isHidden)
        XCTAssertFalse(mirror.actionButton.isHidden)

        XCTAssertEqual(mirror.messageLabel.attributedText, NSAttributedString(string: "Ola"))
        XCTAssertEqual(mirror.imageView.image, UIImage.appleIcon)
        XCTAssertEqual(mirror.detailsLabel.text, "Dolores eum")
        XCTAssertEqual(mirror.actionButton.titleLabel?.text, actionButtonConfig.title)
    }

    func testGivenACompactVerticalSizeClassItWillHideTheImageView() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        viewController.configure(image: .appleIcon)

        // When
        viewController.willTransition(to: UITraitCollection(verticalSizeClass: .compact),
                                      with: MockViewControllerTransitionCoordinator())

        // Then
        XCTAssertTrue(mirror.imageView.isHidden)
    }

    func testGivenANonCompactVerticalSizeClassItWillNotHideTheImageView() throws {
        // Given
        let viewController = EmptyStateViewController()
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)

        viewController.configure(image: .appleIcon)

        // When
        viewController.willTransition(to: UITraitCollection(verticalSizeClass: .regular),
                                      with: MockViewControllerTransitionCoordinator())

        // Then
        XCTAssertFalse(mirror.imageView.isHidden)
    }
}

// MARK: - Mirroring

private extension EmptyStateViewControllerTests {
    struct EmptyStateViewControllerMirror {
        let messageLabel: UILabel
        let imageView: UIImageView
        let detailsLabel: UILabel
        let actionButton: UIButton
    }

    func mirror(of viewController: EmptyStateViewController) throws -> EmptyStateViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)

        return EmptyStateViewControllerMirror(
            messageLabel: try XCTUnwrap(mirror.descendant("messageLabel") as? UILabel),
            imageView: try XCTUnwrap(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try XCTUnwrap(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try XCTUnwrap(mirror.descendant("actionButton") as? UIButton)
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
