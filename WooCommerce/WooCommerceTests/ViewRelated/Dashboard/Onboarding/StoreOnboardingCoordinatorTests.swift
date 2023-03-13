import TestKit
import XCTest
@testable import WooCommerce

@MainActor
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

    func test_starting_with_customDomains_task_presents_DomainSettingsHostingController() throws {
        // Given
        let coordinator = StoreOnboardingCoordinator(navigationController: navigationController, site: .fake())

        // When
        coordinator.start(task: .init(isComplete: true, type: .customizeDomains))
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        let presentedNavigationController = try XCTUnwrap(coordinator.navigationController.presentedViewController as? WooNavigationController)
        assertThat(presentedNavigationController.topViewController, isAnInstanceOf: DomainSettingsHostingController.self)
    }
}
