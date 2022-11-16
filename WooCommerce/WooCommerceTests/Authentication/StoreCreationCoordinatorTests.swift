import TestKit
import XCTest
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

    // MARK: - Presentation in different states for store creation M1

    func test_AuthenticatedWebViewController_is_presented_when_navigationController_is_presenting_another_view_with_storeCreationM2_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: false)
        let coordinator = StoreCreationCoordinator(source: .storePicker,
                                                   navigationController: navigationController,
                                                   featureFlagService: featureFlagService)
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
            self.navigationController.presentedViewController is WooNavigationController
        }
        let storeCreationNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storeCreationNavigationController.topViewController, isAnInstanceOf: AuthenticatedWebViewController.self)
    }

    func test_AuthenticatedWebViewController_is_presented_when_navigationController_is_showing_another_view_with_storeCreationM2_disabled() throws {
        // Given
        navigationController.show(.init(), sender: nil)
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: false)
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .loginEmailError),
                                                   navigationController: navigationController,
                                                   featureFlagService: featureFlagService)
        XCTAssertNotNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is WooNavigationController
        }
        let storeCreationNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storeCreationNavigationController.topViewController, isAnInstanceOf: AuthenticatedWebViewController.self)
    }

    // MARK: - Presentation in different states for store creation M2

    func test_StoreNameFormHostingController_is_presented_when_navigationController_is_presenting_another_view() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: true)
        let coordinator = StoreCreationCoordinator(source: .storePicker,
                                                   navigationController: navigationController,
                                                   featureFlagService: featureFlagService)
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
            self.navigationController.presentedViewController is UINavigationController
        }
        let storeCreationNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storeCreationNavigationController.topViewController, isAnInstanceOf: StoreNameFormHostingController.self)
    }

    func test_StoreNameFormHostingController_is_presented_when_navigationController_is_showing_another_view() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: true)
        navigationController.show(.init(), sender: nil)
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .loginEmailError),
                                                   navigationController: navigationController,
                                                   featureFlagService: featureFlagService)
        XCTAssertNotNil(navigationController.topViewController)
        XCTAssertNil(navigationController.presentedViewController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is UINavigationController
        }
        let storeCreationNavigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        assertThat(storeCreationNavigationController.topViewController, isAnInstanceOf: StoreNameFormHostingController.self)
    }
}
