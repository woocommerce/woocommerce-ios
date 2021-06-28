import TestKit
import WordPressAuthenticator
import XCTest
@testable import WooCommerce
import Yosemite

final class AppCoordinatorTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: StoresManager!
    private var authenticationManager: AuthenticationManager!
    private var defaults: UserDefaults!

    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()

        defaults = UserDefaults(suiteName: Constants.suiteName)
        sessionManager = .makeForTesting(authenticated: false)
        stores = MockStoresManager(sessionManager: sessionManager)
        authenticationManager = AuthenticationManager()
        authenticationManager.initialize()
    }

    override func tearDown() {
        authenticationManager = nil
        sessionManager.defaultStoreID = nil
        stores = nil
        sessionManager = nil
        defaults.removePersistentDomain(forName: Constants.suiteName)

        // If not resetting the window, `AsyncDictionaryTests.testAsyncUpdatesWhereTheFirstOperationFinishesLast` fails.
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_starting_app_logged_out_presents_authentication() throws {
        // Given
        let appCoordinator = AppCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    func test_starting_app_logged_in_without_selected_site_presents_store_picker() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.credentials)
        sessionManager.defaultStoreID = nil
        let appCoordinator = AppCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        let storePickerNavigationController = try XCTUnwrap(window.rootViewController?.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_starting_app_logged_in_with_selected_site_stays_on_tabbar() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        sessionManager.defaultStoreID = 134
        let appCoordinator = AppCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: MainTabBarController.self)
    }

    func test_starting_app_logged_in_with_selected_site_and_ineligible_status_presents_role_error() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        sessionManager.defaultStoreID = 134
        defaults.setValue(Constants.sampleErrorInfoDictionary, forKey: Constants.errorInfoUDKey) // set mock data in defaults
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)
        let appCoordinator = AppCoordinator(window: window, stores: stores, authenticationManager: authenticationManager, roleEligibilityUseCase: useCase)

        // When
        appCoordinator.start()

        // Then
        guard let navigationController = window.rootViewController as? UINavigationController else {
            XCTFail()
            return
        }
        assertThat(navigationController.visibleViewController, isAnInstanceOf: RoleErrorViewController.self)
    }

    func test_starting_app_logged_in_then_logging_out_presents_authentication() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        sessionManager.defaultStoreID = 134
        let appCoordinator = AppCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()
        stores.deauthenticate()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }
}

private extension AppCoordinatorTests {
    struct Constants {
        static let sampleErrorInfoDictionary = ["name": "Patrick", "roles": "author,editor"]
        static let errorInfoUDKey = "wc_eligibility_error_info"
        static let suiteName = "AppCoordinatorTests"
    }
}
