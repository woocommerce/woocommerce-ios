import TestKit
import XCTest
import Yosemite

@testable import WooCommerce
import WordPressUI

final class AddProductCoordinatorTests: XCTestCase {
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

    func test_it_presents_bottom_sheet_on_start() throws {
        // Arrange
        let coordinator = makeAddProductCoordinator()

        // Action
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Assert
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: BottomSheetViewController.self)
    }
}

private extension AddProductCoordinatorTests {
    func makeAddProductCoordinator() -> AddProductCoordinator {
        let sourceView = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        return AddProductCoordinator(siteID: 100, sourceView: sourceView, sourceNavigationController: navigationController)
    }
}
