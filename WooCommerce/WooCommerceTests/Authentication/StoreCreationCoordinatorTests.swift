import TestKit
import XCTest
@testable import WooCommerce

final class StoreCreationCoordinatorTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var navigationController: UINavigationController!
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        window.makeKeyAndVisible()
        navigationController = .init()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        window.resignKey()
        window.rootViewController = nil
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - Presentation in different states

    func test_AuthenticatedWebViewController_is_presented_when_navigationController_is_presenting_another_view() throws {
        // Given
        let coordinator = StoreCreationCoordinator(source: .storePicker, navigationController: navigationController)
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

    func test_AuthenticatedWebViewController_is_presented_when_navigationController_is_showing_another_view() throws {
        // Given
        navigationController.show(.init(), sender: nil)
        let coordinator = StoreCreationCoordinator(source: .loggedOut(source: .loginEmailError), navigationController: navigationController)
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
}
