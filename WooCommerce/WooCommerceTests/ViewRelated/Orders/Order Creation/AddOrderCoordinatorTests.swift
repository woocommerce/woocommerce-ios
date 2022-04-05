import TestKit
import XCTest
import Yosemite

@testable import WooCommerce
import WordPressUI

final class AddOrderCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        self.window = window
    }

    override func tearDown() {
        navigationController = nil

        // Resets `UIWindow` and its view hierarchy so that it can be deallocated cleanly.
        window?.resignKey()
        window?.rootViewController = nil

        super.tearDown()
    }

    func test_it_presents_bottom_sheet_on_start() throws {
        // Given
        let coordinator = makeAddProductCoordinator()

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: BottomSheetViewController.self)
    }
}

private extension AddOrderCoordinatorTests {
    func makeAddProductCoordinator() -> AddOrderCoordinator {
        let sourceView = UIView()
        return AddOrderCoordinator(siteID: 100,
                                   sourceView: sourceView,
                                   sourceNavigationController: navigationController)
    }
}
