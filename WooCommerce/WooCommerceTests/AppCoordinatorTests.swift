import TestKit
import WordPressAuthenticator
import XCTest
@testable import WooCommerce
import Yosemite

final class AppCoordinatorTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!
    private var authenticationManager: AuthenticationManager!

    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()

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

        // If not resetting the window, `AsyncDictionaryTests.testAsyncUpdatesWhereTheFirstOperationFinishesLast` fails.
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_starting_app_logged_out_presents_authentication() throws {
        // Given
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

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
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        let storePickerNavigationController = try XCTUnwrap(window.rootViewController?.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_starting_app_logged_in_with_selected_site_stays_on_tabbar() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.loadEligibilityErrorInfo(completion) = action else {
                return
            }
            // any failure except `.insufficientRole` will be treated as having an eligible status.
            completion(.failure(SampleError.first))
        }
        sessionManager.defaultStoreID = 134
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: MainTabBarController.self)
    }

    func test_starting_app_logged_in_with_selected_site_and_ineligible_status_presents_role_error() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.loadEligibilityErrorInfo(completion) = action else {
                return
            }
            // returning an error info means that it will be treated as ineligible.
            let errorInfo = StorageEligibilityErrorInfo(name: "John Doe", roles: ["author", "editor"])
            completion(.success(errorInfo))
        }
        sessionManager.defaultStoreID = 134
        let useCase = RoleEligibilityUseCase(stores: stores)
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager, roleEligibilityUseCase: useCase)

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
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()
        stores.deauthenticate()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }
}

private extension AppCoordinatorTests {
    /// Convenience method to make AppCoordinator instances.
    func makeCoordinator(window: UIWindow? = nil,
                         stores: StoresManager? = nil,
                         authenticationManager: Authentication? = nil,
                         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol? = nil) -> AppCoordinator {
        return AppCoordinator(window: window ?? self.window,
                              stores: stores ?? self.stores,
                              authenticationManager: authenticationManager ?? self.authenticationManager,
                              roleEligibilityUseCase: roleEligibilityUseCase ?? MockRoleEligibilityUseCase())
    }
}
