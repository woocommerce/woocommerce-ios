import TestKit
import XCTest
import Yosemite

@testable import WooCommerce
import WordPressUI

final class AddOrderCoordinatorTests: XCTestCase {
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

    func test_it_presents_bottom_sheet_when_all_types_are_available() throws {
        // Given
        let coordinator = makeAddProductCoordinator(isOrderCreationEnabled: true,
                                                    shouldShowSimplePaymentsButton: true)

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: BottomSheetViewController.self)
    }

    func test_it_does_nothing_when_all_types_are_unaviable() throws {
        // Given
        let coordinator = makeAddProductCoordinator(isOrderCreationEnabled: false,
                                                    shouldShowSimplePaymentsButton: false)

        // When
        coordinator.start()

        // Then
        XCTAssertNil(coordinator.navigationController.presentedViewController)
    }

    func test_it_opens_simple_payments_when_its_only_available_type() throws {
        // Given
        let coordinator = makeAddProductCoordinator(isOrderCreationEnabled: false,
                                                    shouldShowSimplePaymentsButton: true)

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        let presentedNC = coordinator.navigationController.presentedViewController as? UINavigationController
        assertThat(presentedNC, isAnInstanceOf: WooNavigationController.self)
        assertThat(presentedNC?.topViewController, isAnInstanceOf: SimplePaymentsAmountHostingController.self)
    }
}

private extension AddOrderCoordinatorTests {
    func makeAddProductCoordinator(isOrderCreationEnabled: Bool, shouldShowSimplePaymentsButton: Bool) -> AddOrderCoordinator {
        let sourceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        return AddOrderCoordinator(siteID: 100,
                                   isOrderCreationEnabled: isOrderCreationEnabled,
                                   shouldShowSimplePaymentsButton: shouldShowSimplePaymentsButton,
                                   sourceBarButtonItem: sourceBarButtonItem,
                                   sourceNavigationController: navigationController)
    }
}
