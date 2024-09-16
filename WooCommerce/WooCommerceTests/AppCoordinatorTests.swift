import Experiments
import TestKit
import WordPressAuthenticator
import XCTest
@testable import WooCommerce
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

final class AppCoordinatorTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var authenticationManager: AuthenticationManager!
    private var coordinator: AppCoordinator?

    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()

        window.makeKeyAndVisible()

        sessionManager = .makeForTesting(authenticated: false)
        stores = MockStoresManager(sessionManager: sessionManager)
        storageManager = MockStorageManager()
        authenticationManager = AuthenticationManager()
        authenticationManager.initialize()
    }

    override func tearDown() {
        authenticationManager = nil
        sessionManager.defaultStoreID = nil
        stores = nil
        storageManager = nil
        sessionManager = nil

        // If not resetting the window, `AsyncDictionaryTests.testAsyncUpdatesWhereTheFirstOperationFinishesLast` fails.
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_starting_app_logged_out_presents_authentication() throws {
        // Given
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    func test_starting_app_logged_in_without_selected_site_presents_store_picker_if_there_are_connected_stores() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = nil

        let site = Site.fake().copy(siteID: 123, isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: site)
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        let storePickerNavigationController = try XCTUnwrap(window.rootViewController?.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_starting_app_logged_in_without_selected_site_presents_store_picker_if_there_are_no_connected_stores() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = nil

        let site = Site.fake().copy(siteID: 123, isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: site)
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        let storePickerNavigationController = try XCTUnwrap(window.rootViewController?.presentedViewController as? UINavigationController)
        assertThat(storePickerNavigationController.topViewController, isAnInstanceOf: StorePickerViewController.self)
    }

    func test_starting_app_logged_in_with_wporg_credentials_but_no_selected_site_shows_prologue_screen() {
        // Given
        // Authenticates the app without selecting a site, so that the prologue screen is shown.
        stores.authenticate(credentials: SessionSettings.wporgCredentials)
        sessionManager.defaultStoreID = nil

        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    func test_starting_app_logged_in_with_applicationPassword_credentials_but_no_selected_site_shows_prologue_screen() {
        // Given
        // Authenticates the app without selecting a site, so that the prologue screen is shown.
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        sessionManager.defaultStoreID = nil

        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    func test_starting_app_logged_in_without_selected_site_presents_account_mismatched_if_there_is_no_store_matching_the_error_site_address() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = nil

        let site = Site.fake().copy(siteID: 123, url: "https://abc.com", isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: site)

        let settings = MockLoggedOutAppSettings(errorLoginSiteAddress: "https://test.com")
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: settings)

        // When
        appCoordinator.start()

        // Then
        let loginNavigationController = try XCTUnwrap(window.rootViewController as? LoginNavigationController)
        waitUntil {
            // it takes some time for `show()` to insert the controller to the stack
            // so we have to wait a bit
            loginNavigationController.viewControllers.count > 1
        }
        XCTAssertTrue(loginNavigationController.topViewController is ULAccountMismatchViewController)
    }

    func test_starting_app_logged_in_without_selected_site_presents_error_if_the_error_site_address_does_not_have_woo() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = nil

        let siteURL = "https://test.com"
        let site = Site.fake().copy(siteID: 123, url: siteURL, isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: site)

        let settings = MockLoggedOutAppSettings(errorLoginSiteAddress: siteURL)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: settings)

        // When
        appCoordinator.start()

        // Then
        let loginNavigationController = try XCTUnwrap(window.rootViewController as? LoginNavigationController)
        waitUntil {
            // it takes some time for `show()` to insert the controller to the stack
            // so we have to wait a bit
            loginNavigationController.viewControllers.count > 1
        }
        XCTAssertTrue(loginNavigationController.topViewController is ULErrorViewController)
    }

    func test_starting_app_logged_in_with_selected_site_stays_on_tabbar() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
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

    func test_starting_app_logged_in_with_wporg_credentials_and_selected_site_stays_on_tabbar() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.wporgCredentials)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.loadEligibilityErrorInfo(completion) = action else {
                return
            }
            // any failure except `.insufficientRole` will be treated as having an eligible status.
            completion(.failure(SampleError.first))
        }
        sessionManager.defaultStoreID = WooConstants.placeholderStoreID
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: MainTabBarController.self)
    }

    func test_starting_app_logged_in_with_application_password_credentials_and_selected_site_stays_on_tabbar() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.loadEligibilityErrorInfo(completion) = action else {
                return
            }
            // any failure except `.insufficientRole` will be treated as having an eligible status.
            completion(.failure(SampleError.first))
        }
        sessionManager.defaultStoreID = WooConstants.placeholderStoreID
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: MainTabBarController.self)
    }

    func test_starting_app_logged_in_with_selected_site_and_ineligible_status_presents_role_error() throws {
        // Given
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
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
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = 134
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))

        // When
        appCoordinator.start()
        stores.deauthenticate()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    // MARK: - Login onboarding

    func test_starting_app_logged_out_without_interacting_with_onboarding_presents_onboarding_over_authentication() throws {
        // Given
        stores.deauthenticate()
        sessionManager.defaultStoreID = 134
        let loggedOutAppSettings = MockLoggedOutAppSettings(hasFinishedOnboarding: false)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: loggedOutAppSettings)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: UIViewController.self)
        assertThat(window.rootViewController?.presentedViewController, isAnInstanceOf: LoginOnboardingViewController.self)
    }

    func test_starting_app_logged_out_after_interacting_with_onboarding_does_not_present_onboarding() throws {
        // Given
        stores.deauthenticate()
        sessionManager.defaultStoreID = 134
        let loggedOutAppSettings = MockLoggedOutAppSettings(hasFinishedOnboarding: true)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: loggedOutAppSettings)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
        XCTAssertNil(window.rootViewController?.presentedViewController)
    }

    // MARK: - Login onboarding analytics

    func test_loginOnboardingShown_is_tracked_after_presenting_onboarding() throws {
        // Given
        stores.deauthenticate()
        let analytics = MockAnalyticsProvider()
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             analytics: WooAnalytics(analyticsProvider: analytics),
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: false))

        // When
        appCoordinator.start()

        // Then
        _ = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == WooAnalyticsStat.loginOnboardingShown.rawValue}))
    }

    func test_authenticationManager_handleAuthenticationUrl_with_login_url_updates_root_to_LoginNavigationController_when_onboarding_is_shown() throws {
        // Given
        let appCoordinator = makeCoordinator(authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: false))
        coordinator = appCoordinator
        let url = try XCTUnwrap(URL(string: "woocommerce://app-login?siteUrl=http%3A%2F%2Fwcdev.local&username=user"))

        appCoordinator.start()
        XCTAssertFalse(window.rootViewController is LoginNavigationController)
        assertThat(window.rootViewController?.topmostPresentedViewController, isAnInstanceOf: LoginOnboardingViewController.self)

        // When
        let rootViewController = try XCTUnwrap(window.rootViewController)
        XCTAssertTrue(authenticationManager.handleAuthenticationUrl(url, options: [:], rootViewController: rootViewController))

        // Then
        waitUntil {
            self.window.rootViewController is UINavigationController
        }
        let loginNavigationController = try XCTUnwrap(window.rootViewController as? LoginNavigationController)
        XCTAssertEqual(loginNavigationController.viewControllers.count, 2)
    }

    func test_authenticationManager_handleAuthenticationUrl_with_login_url_pushes_a_view_controller_when_onboarding_is_not_shown() throws {
        // Given
        let appCoordinator = makeCoordinator(authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))
        coordinator = appCoordinator
        let url = try XCTUnwrap(URL(string: "woocommerce://app-login?siteUrl=http%3A%2F%2Fwcdev.local&username=user"))

        appCoordinator.start()
        waitUntil {
            self.window.rootViewController is UINavigationController
        }
        let loginNavigationController = try XCTUnwrap(window.rootViewController as? LoginNavigationController)
        XCTAssertEqual(loginNavigationController.viewControllers.count, 1)

        // When
        XCTAssertTrue(authenticationManager.handleAuthenticationUrl(url, options: [:], rootViewController: loginNavigationController))

        // Then
        XCTAssertEqual(window.rootViewController, loginNavigationController)
        XCTAssertEqual(loginNavigationController.viewControllers.count, 2)
    }

    func test_authenticationManager_handleAuthenticationUrl_with_login_url_dismisses_modal_and_pushes_view_controller_when_modal_is_shown() throws {
        // Given
        let appCoordinator = makeCoordinator(authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))
        coordinator = appCoordinator
        let url = try XCTUnwrap(URL(string: "woocommerce://app-login?siteUrl=http%3A%2F%2Fwcdev.local&username=user"))

        appCoordinator.start()
        waitUntil {
            self.window.rootViewController is UINavigationController
        }
        let loginNavigationController = try XCTUnwrap(window.rootViewController as? LoginNavigationController)
        XCTAssertEqual(loginNavigationController.viewControllers.count, 1)
        XCTAssertNil(loginNavigationController.presentedViewController)

        // When
        loginNavigationController.present(.init(), animated: false)
        waitUntil {
            loginNavigationController.presentedViewController != nil
        }
        XCTAssertTrue(authenticationManager.handleAuthenticationUrl(url, options: [:], rootViewController: loginNavigationController))

        // Then
        XCTAssertEqual(window.rootViewController, loginNavigationController)
        waitUntil {
            loginNavigationController.viewControllers.count == 2
        }
        XCTAssertNil(loginNavigationController.presentedViewController)
    }

    func test_appCoordinator_start_resets_default_store_and_proceeds_to_login_when_isAuthenticated_and_needsDefaultStore_are_false() {
        // Given
        stores.updateDefaultStore(storeID: 123)
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertFalse(stores.needsDefaultStore)

        let appCoordinator = makeCoordinator(authenticationManager: authenticationManager,
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))

        // When
        appCoordinator.start()

        // Then
        waitUntil {
            self.window.rootViewController is LoginNavigationController
        }
        XCTAssertTrue(stores.needsDefaultStore)
    }
}

private extension AppCoordinatorTests {
    /// Convenience method to make AppCoordinator instances.
    func makeCoordinator(window: UIWindow? = nil,
                         stores: StoresManager? = nil,
                         authenticationManager: Authentication? = nil,
                         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol? = nil,
                         analytics: Analytics = ServiceLocator.analytics,
                         loggedOutAppSettings: LoggedOutAppSettingsProtocol = MockLoggedOutAppSettings(),
                         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
                         featureFlagService: FeatureFlagService = MockFeatureFlagService(),
                         upgradesViewPresentationCoordinator: UpgradesViewPresentationCoordinator = UpgradesViewPresentationCoordinator(),
                         switchStoreUseCase: SwitchStoreUseCaseProtocol? = nil,
                         themeInstaller: ThemeInstaller = DefaultThemeInstaller()
    ) -> AppCoordinator {
        return AppCoordinator(window: window ?? self.window,
                              stores: stores ?? self.stores,
                              storageManager: storageManager ?? self.storageManager,
                              authenticationManager: authenticationManager ?? self.authenticationManager,
                              roleEligibilityUseCase: roleEligibilityUseCase ?? MockRoleEligibilityUseCase(),
                              analytics: analytics,
                              loggedOutAppSettings: loggedOutAppSettings,
                              pushNotesManager: pushNotesManager,
                              featureFlagService: featureFlagService,
                              upgradesViewPresentationCoordinator: upgradesViewPresentationCoordinator,
                              switchStoreUseCase: switchStoreUseCase,
                              themeInstaller: themeInstaller)
    }
}
