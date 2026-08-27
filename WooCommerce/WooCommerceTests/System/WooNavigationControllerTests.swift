import Testing
import UIKit
import WooFoundation
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct WooNavigationControllerTests {

    @Test func test_setNavigationBarHiddenIfNeeded_when_navigation_bar_is_already_in_requested_state_then_does_not_update_it() {
        // Given
        let navigationController = NavigationBarVisibilitySpyNavigationController()
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.resetVisibilityUpdates()

        // When
        navigationController.setNavigationBarHiddenIfNeeded(false, animated: true)

        // Then
        #expect(navigationController.visibilityUpdates.isEmpty)
    }

    @Test func test_setNavigationBarHiddenIfNeeded_when_navigation_bar_visibility_differs_then_updates_it() {
        // Given
        let navigationController = NavigationBarVisibilitySpyNavigationController()
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.resetVisibilityUpdates()

        // When
        navigationController.setNavigationBarHiddenIfNeeded(true, animated: false)

        // Then
        #expect(navigationController.visibilityUpdates.count == 1)
        #expect(navigationController.visibilityUpdates.first?.hidden == true)
        #expect(navigationController.visibilityUpdates.first?.animated == false)
    }

    @Test func test_did_show_view_controller_then_posts_navigation_notification() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        let sut = WooNavigationControllerDelegate(connectivityObserver: connectivityObserver)
        let navigationController = StableNavigationController()
        let viewController = UIViewController()
        var notifiedNavigationController: UINavigationController?
        let observer = NotificationCenter.default.addObserver(forName: .wooNavigationControllerDidShowViewController,
                                                              object: navigationController,
                                                              queue: nil) { notification in
            notifiedNavigationController = notification.object as? UINavigationController
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // When
        sut.navigationController(navigationController, didShow: viewController, animated: false)

        // Then
        #expect(notifiedNavigationController === navigationController)
    }

    @Test func test_connectivity_change_when_current_controller_is_visible_and_top_then_updates_offline_banner() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        let sut = WooNavigationControllerDelegate(connectivityObserver: connectivityObserver)
        let viewController = OfflineBannerViewController()
        let navigationController = StableNavigationController(rootViewController: viewController)
        let window = makeVisibleWindow(rootViewController: navigationController)
        sut.navigationController(navigationController, didShow: viewController, animated: false)

        // When
        connectivityObserver.setStatus(.notReachable)

        // Then
        #expect(viewController.view.subviews.contains { $0 is OfflineBannerView })
        #expect(viewController.additionalSafeAreaInsets.bottom == OfflineBannerView.height)
        _ = window
    }

    @Test func test_connectivity_change_when_current_controller_is_no_longer_top_then_does_not_update_offline_banner() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        let sut = WooNavigationControllerDelegate(connectivityObserver: connectivityObserver)
        let viewController = OfflineBannerViewController()
        let navigationController = StableNavigationController(rootViewController: viewController)
        let window = makeVisibleWindow(rootViewController: navigationController)
        sut.navigationController(navigationController, didShow: viewController, animated: false)
        navigationController.pushViewController(UIViewController(), animated: false)

        // When
        connectivityObserver.setStatus(.notReachable)

        // Then
        #expect(viewController.view.subviews.contains { $0 is OfflineBannerView } == false)
        #expect(viewController.additionalSafeAreaInsets == .zero)
        _ = window
    }

    @Test func test_connectivity_change_when_current_controller_is_not_visible_then_does_not_update_offline_banner() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        let sut = WooNavigationControllerDelegate(connectivityObserver: connectivityObserver)
        let viewController = OfflineBannerViewController()
        let navigationController = StableNavigationController(rootViewController: viewController)
        sut.navigationController(navigationController, didShow: viewController, animated: false)

        // When
        connectivityObserver.setStatus(.notReachable)

        // Then
        #expect(viewController.view.subviews.contains { $0 is OfflineBannerView } == false)
        #expect(viewController.additionalSafeAreaInsets == .zero)
    }

    @Test func test_view_did_load_then_navigation_controller_does_not_replace_interactive_pop_gesture_delegate() {
        // Given
        let sut = StableNavigationController(rootViewController: UIViewController())

        // When
        sut.loadViewIfNeeded()

        // Then
        #expect(sut.interactivePopGestureRecognizer?.delegate !== sut)
    }

    @Test func test_interactive_pop_gesture_when_navigation_controller_is_at_root_then_does_not_begin() throws {
        // Given
        let sut = StableNavigationController(rootViewController: UIViewController())
        sut.loadViewIfNeeded()
        let gestureRecognizer = try #require(sut.interactivePopGestureRecognizer)

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(gestureRecognizer)

        // Then
        #expect(shouldBegin == false)
    }

    @Test func test_interactive_pop_gesture_when_top_view_controller_allows_swipe_back_then_begins() throws {
        // Given
        let sut = StableNavigationController(rootViewController: UIViewController())
        sut.pushViewController(SwipeBackViewController(shouldPop: true), animated: false)
        sut.loadViewIfNeeded()
        let gestureRecognizer = try #require(sut.interactivePopGestureRecognizer)

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(gestureRecognizer)

        // Then
        #expect(shouldBegin)
    }

    @Test func test_interactive_pop_gesture_when_top_view_controller_blocks_swipe_back_then_does_not_begin() throws {
        // Given
        let sut = StableNavigationController(rootViewController: UIViewController())
        sut.pushViewController(SwipeBackViewController(shouldPop: false), animated: false)
        sut.loadViewIfNeeded()
        let gestureRecognizer = try #require(sut.interactivePopGestureRecognizer)

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(gestureRecognizer)

        // Then
        #expect(shouldBegin == false)
    }

    @Test func test_handle_swipe_back_gesture_then_view_controller_becomes_gesture_delegate() {
        // Given
        let viewController = UIViewController()
        let navigationController = StableNavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(viewController, animated: false)
        navigationController.loadViewIfNeeded()

        // When
        viewController.handleSwipeBackGesture()

        // Then
        #expect(navigationController.interactivePopGestureRecognizer?.delegate === viewController)
    }
}

private extension WooNavigationControllerTests {
    func makeVisibleWindow(rootViewController: UIViewController) -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        rootViewController.view.layoutIfNeeded()
        return window
    }
}

private final class OfflineBannerViewController: UIViewController {
    override var shouldShowOfflineBanner: Bool {
        true
    }
}

private final class StableNavigationController: WooNavigationController {
    override var transitionCoordinator: UIViewControllerTransitionCoordinator? {
        nil
    }
}

private final class NavigationBarVisibilitySpyNavigationController: UINavigationController {
    private(set) var visibilityUpdates: [(hidden: Bool, animated: Bool)] = []

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        visibilityUpdates.append((hidden, animated))
        super.setNavigationBarHidden(hidden, animated: animated)
    }

    func resetVisibilityUpdates() {
        visibilityUpdates = []
    }
}

private final class SwipeBackViewController: UIViewController {
    private let shouldPop: Bool

    init(shouldPop: Bool) {
        self.shouldPop = shouldPop
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldPopOnSwipeBack() -> Bool {
        shouldPop
    }
}
