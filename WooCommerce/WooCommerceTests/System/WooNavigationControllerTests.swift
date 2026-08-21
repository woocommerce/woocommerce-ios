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
