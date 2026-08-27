import Testing
import UIKit
@testable import WooCommerce

/// Serialized because the tests share the app's key window state for real UIKit presentations.
@Suite(.serialized)
@MainActor
struct UIViewControllerSafeModalPresentationTests {

    // MARK: presentIfIdle

    @Test
    func presentIfIdle_when_nothing_is_presented_then_presents() {
        // Given
        let (window, presenter) = makePresenterInWindow()
        defer { window.isHidden = true }
        let modal = UIViewController()

        // When
        presenter.presentIfIdle(modal, animated: false)

        // Then
        #expect(presenter.presentedViewController === modal)
    }

    @Test
    func presentIfIdle_when_another_modal_is_presented_then_drops_the_presentation() {
        // Given
        let (window, presenter) = makePresenterInWindow()
        defer { window.isHidden = true }
        let firstModal = UIViewController()
        presenter.present(firstModal, animated: false)

        // When
        let secondModal = UIViewController()
        presenter.presentIfIdle(secondModal, animated: false)

        // Then
        #expect(presenter.presentedViewController === firstModal)
        #expect(secondModal.presentingViewController == nil)
    }

    @Test
    func presentIfIdle_when_an_alert_is_presented_and_not_dismissing_then_drops_the_presentation() {
        // Given
        let (window, presenter) = makePresenterInWindow()
        defer { window.isHidden = true }
        let alert = UIAlertController(title: "Title", message: nil, preferredStyle: .alert)
        presenter.present(alert, animated: false)

        // When
        let modal = UIViewController()
        presenter.presentIfIdle(modal, animated: false)

        // Then
        #expect(presenter.presentedViewController === alert)
        #expect(modal.presentingViewController == nil)
    }

    @Test
    func presentIfIdle_when_an_alert_is_being_dismissed_then_presents() {
        // Given
        let presenter = PresenterSpy()
        presenter.presentedViewControllerStub = DismissingAlertControllerStub(title: nil, message: nil, preferredStyle: .alert)

        // When
        let modal = UIViewController()
        presenter.presentIfIdle(modal, animated: false)

        // Then
        #expect(presenter.presentCalls.count == 1)
        #expect(presenter.presentCalls.first === modal)
    }

    // MARK: dismissPresentedIfNeeded

    @Test
    func dismissPresentedIfNeeded_when_a_modal_is_presented_then_dismisses_it() async throws {
        // Given
        let (window, presenter) = makePresenterInWindow()
        defer { window.isHidden = true }
        let modal = UIViewController()
        presenter.present(modal, animated: false)

        // When
        presenter.dismissPresentedIfNeeded(animated: false)

        // Then
        try await waitUntil { presenter.presentedViewController == nil }
    }

    @Test
    func dismissPresentedIfNeeded_when_nothing_is_presented_then_does_nothing() {
        // Given
        let (window, presenter) = makePresenterInWindow()
        defer { window.isHidden = true }

        // When
        presenter.dismissPresentedIfNeeded(animated: false)

        // Then
        #expect(presenter.presentedViewController == nil)
    }

    @Test
    func dismissPresentedIfNeeded_when_dismissal_is_in_flight_then_does_not_dismiss_again() {
        // Given
        let presenter = PresenterSpy()
        presenter.presentedViewControllerStub = DismissingAlertControllerStub(title: nil, message: nil, preferredStyle: .alert)

        // When
        presenter.dismissPresentedIfNeeded(animated: false)

        // Then
        #expect(presenter.dismissCallCount == 0)
    }
}

// MARK: - Helpers

private extension UIViewControllerSafeModalPresentationTests {
    func makePresenterInWindow() -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return (window, presenter)
    }

    func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !condition() {
            if Date() > deadline {
                Issue.record("Timed out waiting for condition")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

/// Records presentation calls without running real UIKit transitions, and lets tests
/// stub the presented view controller to simulate an in-flight dismissal.
private final class PresenterSpy: UIViewController {
    var presentedViewControllerStub: UIViewController?
    private(set) var presentCalls: [UIViewController] = []

    override var presentedViewController: UIViewController? {
        presentedViewControllerStub ?? super.presentedViewController
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCalls.append(viewControllerToPresent)
    }
}

/// An alert that reports an in-flight dismissal. `dismissCallCount` is tracked on the alert
/// because `dismissPresentedIfNeeded` dismisses the presented controller directly.
private final class DismissingAlertControllerStub: UIAlertController {
    private(set) var dismissCallCount = 0

    override var isBeingDismissed: Bool {
        true
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCallCount += 1
    }
}

private extension PresenterSpy {
    var dismissCallCount: Int {
        (presentedViewControllerStub as? DismissingAlertControllerStub)?.dismissCallCount ?? 0
    }
}
