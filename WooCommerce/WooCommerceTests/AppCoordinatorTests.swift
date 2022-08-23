import Experiments
import TestKit
import WordPressAuthenticator
import XCTest
@testable import WooCommerce
import Yosemite
import protocol Storage.StorageManagerType

final class AppCoordinatorTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var authenticationManager: AuthenticationManager!

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
        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
    }

    func test_starting_app_logged_in_without_selected_site_presents_store_picker_if_there_are_connected_stores() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.credentials)
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
        stores.authenticate(credentials: SessionSettings.credentials)
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

    func test_starting_app_logged_in_without_selected_site_presents_account_mismatched_if_there_is_no_store_matching_the_error_site_address() throws {
        // Given
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.credentials)
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
        stores.authenticate(credentials: SessionSettings.credentials)
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

    // MARK: - Login onboarding

    func test_starting_app_logged_out_without_interacting_with_onboarding_presents_onboarding_over_authentication() throws {
        // Given
        stores.deauthenticate()
        sessionManager.defaultStoreID = 134
        let loggedOutAppSettings = MockLoggedOutAppSettings(hasFinishedOnboarding: false)
        let featureFlagService = MockFeatureFlagService(isLoginPrologueOnboardingEnabled: true)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: loggedOutAppSettings,
                                             featureFlagService: featureFlagService)

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
        let featureFlagService = MockFeatureFlagService(isLoginPrologueOnboardingEnabled: true)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: loggedOutAppSettings,
                                             featureFlagService: featureFlagService)

        // When
        appCoordinator.start()

        // Then
        assertThat(window.rootViewController, isAnInstanceOf: LoginNavigationController.self)
        XCTAssertNil(window.rootViewController?.presentedViewController)
    }

    func test_starting_app_logged_out_does_not_present_onboarding_when_feature_flag_is_disabled() throws {
        // Given
        stores.deauthenticate()
        sessionManager.defaultStoreID = 134
        let loggedOutAppSettings = MockLoggedOutAppSettings(hasFinishedOnboarding: false)
        let featureFlagService = MockFeatureFlagService(isLoginPrologueOnboardingEnabled: false)
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             loggedOutAppSettings: loggedOutAppSettings,
                                             featureFlagService: featureFlagService)

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
                                             loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: false),
                                             featureFlagService: MockFeatureFlagService(isLoginPrologueOnboardingEnabled: true))

        // When
        appCoordinator.start()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.loginOnboardingShown.rawValue])
    }

    // MARK: - Login reminder analytics

    func test_loginLocalNotificationTapped_is_tracked_after_notification_contact_support_action() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let pushNotesManager = MockPushNotificationsManager()
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             analytics: WooAnalytics(analyticsProvider: analytics),
                                             pushNotesManager: pushNotesManager)
        appCoordinator.start()

        // When
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: LocalNotification.Action.contactSupport.rawValue,
                                                              requestIdentifier: LocalNotification.Scenario.loginSiteAddressError.rawValue))
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.loginLocalNotificationTapped.rawValue])
        let actionPropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["action"] as? String)
        XCTAssertEqual(actionPropertyValue, "contact_support")
        let typePropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["type"] as? String)
        XCTAssertEqual(typePropertyValue, "site_address_error")
    }

    func test_loginLocalNotificationTapped_is_tracked_after_notification_loginWithWPCom_action() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let pushNotesManager = MockPushNotificationsManager()
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             analytics: WooAnalytics(analyticsProvider: analytics),
                                             pushNotesManager: pushNotesManager)
        appCoordinator.start()

        // When
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: LocalNotification.Action.loginWithWPCom.rawValue,
                                                              requestIdentifier: LocalNotification.Scenario.loginSiteAddressError.rawValue))
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.loginLocalNotificationTapped.rawValue])
        let actionPropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["action"] as? String)
        XCTAssertEqual(actionPropertyValue, "login_with_wpcom")
        let typePropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["type"] as? String)
        XCTAssertEqual(typePropertyValue, "site_address_error")
    }

    func test_loginLocalNotificationTapped_is_tracked_after_notification_tap_action() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let pushNotesManager = MockPushNotificationsManager()
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             analytics: WooAnalytics(analyticsProvider: analytics),
                                             pushNotesManager: pushNotesManager)
        appCoordinator.start()

        // When
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier,
                                                              requestIdentifier: LocalNotification.Scenario.loginSiteAddressError.rawValue))
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.loginLocalNotificationTapped.rawValue])
        let actionPropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["action"] as? String)
        XCTAssertEqual(actionPropertyValue, "default")
        let typePropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["type"] as? String)
        XCTAssertEqual(typePropertyValue, "site_address_error")
    }

    func test_loginLocalNotificationDismissed_is_tracked_after_notification_dismiss_action() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let pushNotesManager = MockPushNotificationsManager()
        let appCoordinator = makeCoordinator(window: window,
                                             stores: stores,
                                             authenticationManager: authenticationManager,
                                             analytics: WooAnalytics(analyticsProvider: analytics),
                                             pushNotesManager: pushNotesManager)
        appCoordinator.start()

        // When
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: UNNotificationDismissActionIdentifier,
                                                              requestIdentifier: LocalNotification.Scenario.loginSiteAddressError.rawValue))
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.loginLocalNotificationDismissed.rawValue])
        let typePropertyValue = try XCTUnwrap(analytics.receivedProperties.first?["type"] as? String)
        XCTAssertEqual(typePropertyValue, "site_address_error")
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
                         featureFlagService: FeatureFlagService = MockFeatureFlagService()) -> AppCoordinator {
        return AppCoordinator(window: window ?? self.window,
                              stores: stores ?? self.stores,
                              storageManager: storageManager ?? self.storageManager,
                              authenticationManager: authenticationManager ?? self.authenticationManager,
                              roleEligibilityUseCase: roleEligibilityUseCase ?? MockRoleEligibilityUseCase(),
                              analytics: analytics,
                              loggedOutAppSettings: loggedOutAppSettings,
                              pushNotesManager: pushNotesManager,
                              featureFlagService: featureFlagService)
    }
}
