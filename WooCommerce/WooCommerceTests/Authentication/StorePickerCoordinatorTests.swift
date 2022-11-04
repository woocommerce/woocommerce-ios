import WordPressAuthenticator
import TestKit
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

    func test_storeCreationFromLogin_configuration_shows_storePicker_then_presents_storeCreation() throws {
        // Given
        let coordinator = StorePickerCoordinator(navigationController, config: .storeCreationFromLogin(source: .prologue))

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        // Store picker should be pushed to the navigation stack.
        assertThat(navigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)

        let storeCreationNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storeCreationNavigationController.topViewController, isAnInstanceOf: AuthenticatedWebViewController.self)
    }
}
