import TestKit
import XCTest
@testable import WooCommerce

final class StoreOnboardingCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_starting_with_storeDetails_task_presents_AuthenticatedWebViewController() throws {
        // Given
        let coordinator = StoreOnboardingCoordinator(navigationController: navigationController, site: .fake(), onTaskCompleted: { _ in }, reloadTasks: {})

        // When
        coordinator.start(task: .init(isComplete: true, type: .storeDetails))
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        let presentedNavigationController = try XCTUnwrap(coordinator.navigationController.presentedViewController as? WooNavigationController)
        assertThat(presentedNavigationController.topViewController, isAnInstanceOf: AuthenticatedWebViewController.self)
    }
}
