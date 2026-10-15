import Testing
import UIKit
import WordPressUI

@MainActor
struct UIViewControllerTopmostVisiblePresenterTests {
    @Test func test_topmostVisiblePresenter_when_nothing_is_presented_then_returns_self() throws {
        // Given
        let window = makeWindow()
        defer { window.isHidden = true }
        let root = try #require(window.rootViewController)

        // Then
        #expect(root.topmostVisiblePresenter === root)
        #expect(window.topmostVisiblePresenter === root)
    }

    @Test func test_topmostVisiblePresenter_when_presentation_chain_is_on_screen_then_returns_the_leaf() async throws {
        // Given
        let window = makeWindow()
        defer { window.isHidden = true }
        let root = try #require(window.rootViewController)
        let first = UIViewController()
        let second = UIViewController()
        await present(first, on: root)
        await present(second, on: first)

        // Then
        #expect(root.topmostVisiblePresenter === second)
        #expect(root.topmostPresentedViewController === second)
    }

    @Test func test_topmostVisiblePresenter_when_chain_is_full_screen_then_returns_the_leaf() async throws {
        // Given a full-screen chain, where UIKit detaches each covered presenter's view
        let window = makeWindow()
        defer { window.isHidden = true }
        let root = try #require(window.rootViewController)
        let first = UIViewController()
        first.modalPresentationStyle = .fullScreen
        let second = UIViewController()
        second.modalPresentationStyle = .fullScreen
        await present(first, on: root)
        await present(second, on: first)

        // Then the detached intermediate presenter doesn't stop the walk
        #expect(first.viewIfLoaded?.window == nil)
        #expect(root.topmostVisiblePresenter === second)
    }

    @Test func test_topmostVisiblePresenter_when_leaf_is_being_dismissed_then_returns_its_presenter() async throws {
        // Given
        let window = makeWindow()
        defer { window.isHidden = true }
        let root = try #require(window.rootViewController)
        let first = UIViewController()
        let second = UIViewController()
        await present(first, on: root)
        await present(second, on: first)

        // When
        second.dismiss(animated: true)

        // Then the controller going away is skipped, while `topmostPresentedViewController` still reports it.
        #expect(second.isBeingDismissed)
        #expect(root.topmostVisiblePresenter === first)
        #expect(root.topmostPresentedViewController === second)
    }
}

private extension UIViewControllerTopmostVisiblePresenterTests {
    func makeWindow() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        return window
    }

    func present(_ viewController: UIViewController, on presenter: UIViewController) async {
        await withCheckedContinuation { continuation in
            presenter.present(viewController, animated: false) {
                continuation.resume()
            }
        }
    }
}
