import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class StoreCreationCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_StoreNameFormHostingController_is_presented_upon_start() throws {
        // Given
        let coordinator = StoreCreationCoordinator(source: .storePicker,
                                                   navigationController: navigationController)
        waitFor { promise in
            self.navigationController.present(.init(), animated: false) {
                promise(())
            }
        }
        XCTAssertNotNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is StoreNameFormHostingController
        }
    }

    func test_StoreNameFormHostingController_is_presented_when_navigationController_is_showing_another_view() throws {
        // Given
        navigationController.show(.init(), sender: nil)
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .loginEmailError),
                                                   navigationController: navigationController)
        XCTAssertNotNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is StoreNameFormHostingController
        }
    }
}
