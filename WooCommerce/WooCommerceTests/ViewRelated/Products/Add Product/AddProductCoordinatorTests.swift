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

    func test_it_presents_AddProductFromImageHostingController_on_start_when_eligible() throws {
        // Given
        let coordinator = makeAddProductCoordinator(
            addProductFromImageEligibilityChecker: MockAddProductFromImageEligibilityChecker(isEligibleToParticipateInABTest: true, isEligible: true)
        )

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        let navigationController = try XCTUnwrap(coordinator.navigationController.presentedViewController as? UINavigationController)
        assertThat(navigationController.topViewController, isAnInstanceOf: AddProductFromImageHostingController.self)
    }
}

private extension AddProductCoordinatorTests {
    func makeAddProductCoordinator(addProductFromImageEligibilityChecker: AddProductFromImageEligibilityCheckerProtocol =
                                   MockAddProductFromImageEligibilityChecker()) -> AddProductCoordinator {
        let view = UIView()
        return AddProductCoordinator(siteID: 100,
                                     source: .productsTab,
                                     sourceView: view,
                                     sourceNavigationController: navigationController,
                                     addProductFromImageEligibilityChecker: addProductFromImageEligibilityChecker,
                                     isFirstProduct: false)
    }
}
