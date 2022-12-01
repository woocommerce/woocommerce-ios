import TestKit
import WordPressAuthenticator
import XCTest
@testable import WooCommerce

final class StorePickerCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_storeCreationFromLogin_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .storeCreationFromLogin(source: .prologue))

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_standard_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .standard)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_switchingStores_configuration_presents_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .switchingStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        XCTAssertNil(navigationController.topViewController)

        let storePickerNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_login_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .login)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }

    func test_listStores_configuration_shows_storePicker() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .listStores)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.topViewController is StorePickerViewController
        }
    }
}
