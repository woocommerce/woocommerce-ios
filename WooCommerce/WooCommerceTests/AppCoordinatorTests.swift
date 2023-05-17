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
        authenticationManager.initialize(loggedOutAppSettings: MockLoggedOutAppSettings())
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

        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

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

        let appCoordinator = makeCoordinator(window: window, stores: stores, authenticationManager: authenticationManager)

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
        _ = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == WooAnalyticsStat.loginOnboardingShown.rawValue}))
    }

    // MARK: - Handle local notification response

    func test_plans_page_is_displayed_when_tapping_on_oneDayBeforeFreeTrialExpires_notification() throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let coordinator = makeCoordinator(window: window, pushNotesManager: pushNotesManager)
        coordinator.start()
        let siteID: Int64 = 123

        // When
        let response = try XCTUnwrap(MockNotificationResponse(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            requestIdentifier: LocalNotification.Scenario.oneDayBeforeFreeTrialExpires(siteID: siteID, expiryDate: Date()).identifier)
        )
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        waitUntil {
            self.window.rootViewController?.topmostPresentedViewController is UpgradePlanCoordinatingController
        }
    }

    func test_plans_page_is_displayed_when_tapping_on_oneDayAfterFreeTrialExpiresIdentifier_notification() throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let coordinator = makeCoordinator(window: window, pushNotesManager: pushNotesManager)
        coordinator.start()
        let siteID: Int64 = 123

        // When
        let response = try XCTUnwrap(MockNotificationResponse(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            requestIdentifier: LocalNotification.Scenario.oneDayAfterFreeTrialExpires(siteID: siteID).identifier)
        )
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        waitUntil {
            self.window.rootViewController?.topmostPresentedViewController is UpgradePlanCoordinatingController
        }
    }

    // MARK: - Notification to subscribe to free trail after entering store name
    func test_store_creation_flow_starts_upon_tapping_oneDayAfterStoreCreationNameWithoutFreeTrial_notification_when_valid_store_is_selected_already() throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: true,
                                                        isStoreCreationM2WithInAppPurchasesEnabled: false,
                                                        isStoreCreationM3ProfilerEnabled: true)

        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.loadEligibilityErrorInfo(completion) = action else {
                return
            }
            // any failure except `.insufficientRole` will be treated as having an eligible status.
            completion(.failure(SampleError.first))
        }
        let site = Site.fake().copy(siteID: 123, isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: site)
        sessionManager.defaultStoreID = 123

        let coordinator = makeCoordinator(window: window,
                                          stores: stores,
                                          authenticationManager: authenticationManager,
                                          pushNotesManager: pushNotesManager,
                                          featureFlagService: featureFlagService,
                                          purchasesManager: WebPurchasesForWPComPlans(stores: stores))

        let storeName = "SampleStoreName"
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier,
                                                              requestIdentifier: LocalNotification.Scenario.IdentifierPrefix.oneDayAfterStoreCreationNameWithoutFreeTrial,
                                                              notificationUserInfo: [StoreCreationCoordinator.LocalNotificationUserInfoKey.storeName: storeName]))

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .loadPlan(_, completion) = action {
                completion(.success(.init(productID: 1021, name: "", formattedPrice: "")))
            }
        }

        // When
        coordinator.start()
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        let tabBarController = try XCTUnwrap(window.rootViewController as? MainTabBarController)
        let tabBarNavigationController = try XCTUnwrap(tabBarController.selectedViewController as? UINavigationController)
        waitUntil {
            let storeCreationNavigationController = tabBarNavigationController.topmostPresentedViewController as? WooNavigationController
            return storeCreationNavigationController?.topViewController is StoreCreationCategoryQuestionHostingController
        }
    }

    func test_store_creation_flow_starts_upon_tapping_oneDayAfterStoreCreationNameWithoutFreeTrial_notification_when_no_valid_store_available() throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: true,
                                                        isStoreCreationM2WithInAppPurchasesEnabled: false,
                                                        isStoreCreationM3ProfilerEnabled: true)
        // Authenticates the app without selecting a site, so that the store picker is shown.
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        sessionManager.defaultStoreID = nil

        let site = Site.fake().copy(siteID: 123, isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: site)
        let coordinator = makeCoordinator(window: window,
                                          stores: stores,
                                          authenticationManager: authenticationManager,
                                          pushNotesManager: pushNotesManager,
                                          featureFlagService: featureFlagService,
                                          purchasesManager: WebPurchasesForWPComPlans(stores: stores))

        let storeName = "SampleStoreName"
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: UNNotificationDefaultActionIdentifier,
                                                              requestIdentifier: LocalNotification.Scenario.IdentifierPrefix.oneDayAfterStoreCreationNameWithoutFreeTrial,
                                                              notificationUserInfo: [StoreCreationCoordinator.LocalNotificationUserInfoKey.storeName: storeName]))

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .loadPlan(_, completion) = action {
                completion(.success(.init(productID: 1021, name: "", formattedPrice: "")))
            }
        }

        // When
        coordinator.start()
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        let storePickerNavigationController = try XCTUnwrap(window.rootViewController?.presentedViewController as? UINavigationController)
        waitUntil {
            let storeCreationNavigationController = storePickerNavigationController.topmostPresentedViewController as? WooNavigationController
            return storeCreationNavigationController?.topViewController is StoreCreationCategoryQuestionHostingController
        }
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
                         purchasesManager: InAppPurchasesForWPComPlansProtocol? = nil) -> AppCoordinator {
        return AppCoordinator(window: window ?? self.window,
                              stores: stores ?? self.stores,
                              storageManager: storageManager ?? self.storageManager,
                              authenticationManager: authenticationManager ?? self.authenticationManager,
                              roleEligibilityUseCase: roleEligibilityUseCase ?? MockRoleEligibilityUseCase(),
                              analytics: analytics,
                              loggedOutAppSettings: loggedOutAppSettings,
                              pushNotesManager: pushNotesManager,
                              featureFlagService: featureFlagService,
                              purchasesManager: purchasesManager ?? nil)
    }
}
