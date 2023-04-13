import TestKit
import XCTest
import WordPressAuthenticator
import Yosemite
@testable import WooCommerce

/// Test cases for `AuthenticationManager`.
final class AuthenticationManagerTests: XCTestCase {
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

    /// We do not allow automatic WPCOM account sign-up if the user entered an email that is not
    /// registered in WordPress.com. This configuration is set up in
    /// `WordPressAuthenticatorConfiguration` in `AuthenticationManager.initialize()`.
    func test_it_supports_handling_for_unknown_WPCOM_user_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: 7, userInfo: [
            "WordPressComRestApiErrorCodeKey": "unknown_user"
        ])

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_does_not_support_handling_for_unknown_REST_API_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: 7, userInfo: [
            "WordPressComRestApiErrorCodeKey": "rick_rolled"
        ])

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertFalse(canHandle)
    }

    /// We don't allow sites that do not have SSL. We provide a custom error UI for this.
    func test_it_supports_handling_for_non_SSL_site_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorSecureConnectionFailed)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_supports_handling_for_inaccessible_site_URL_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotConnectToHost)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_supports_handling_for_unknown_site_URL_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotFindHost)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_can_create_a_ViewModel_for_unknown_WPCOM_user_errors() throws {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: 7, userInfo: [
            "WordPressComRestApiErrorCodeKey": "unknown_user"
        ])

        // When
        let viewModel = try XCTUnwrap(manager.viewModel(error))

        // Then
        XCTAssertTrue(viewModel is NotWPAccountViewModel)
    }

    func test_it_can_create_a_ViewModel_for_inaccessible_site_errors() throws {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotConnectToHost)

        // When
        let viewModel = try XCTUnwrap(manager.viewModel(error))

        // Then
        XCTAssertTrue(viewModel is NotWPErrorViewModel)
    }

    func test_it_can_create_a_ViewModel_for_unknown_site_URL_errors() throws {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotFindHost)

        // When
        let viewModel = try XCTUnwrap(manager.viewModel(error))

        // Then
        XCTAssertTrue(viewModel is NotWPErrorViewModel)
    }

    func test_it_can_create_a_ViewModel_for_non_SSL_site_errors() throws {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorSecureConnectionFailed)

        // When
        let viewModel = try XCTUnwrap(manager.viewModel(error))

        // Then
        XCTAssertTrue(viewModel is NoSecureConnectionErrorViewModel)
    }

    func test_it_presents_email_controller_for_wpcom_site() {
        // Given
        let manager = AuthenticationManager()
        let siteInfo = siteInfo(exists: true,
                                hasWordPress: true,
                                isWordPressCom: true,
                                hasJetpack: true,
                                isJetpackActive: true,
                                isJetpackConnected: true)
        var result: WordPressAuthenticatorResult?
        let completionHandler: (WordPressAuthenticatorResult) -> Void = { completionResult in
            result = completionResult
        }

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: completionHandler)

        // Then
        guard case .presentEmailController = result else {
            return XCTFail("Unexpected result returned for non-Jetpack site")
        }
    }

    func test_it_presents_email_controller_for_non_wpcom_site_with_jetpack() {
        // Given
        let manager = AuthenticationManager()
        let siteInfo = siteInfo(exists: true,
                                hasWordPress: true,
                                isWordPressCom: false,
                                hasJetpack: true,
                                isJetpackActive: true,
                                isJetpackConnected: true)
        var result: WordPressAuthenticatorResult?
        let completionHandler: (WordPressAuthenticatorResult) -> Void = { completionResult in
            result = completionResult
        }

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: completionHandler)

        // Then
        guard case .presentEmailController = result else {
            return XCTFail("Unexpected result returned for non-Jetpack site")
        }
    }

    func test_it_presents_username_and_password_controller_for_non_wpcom_site_without_jetpack_site() {
        // Given
        let manager = AuthenticationManager()
        let siteInfo = siteInfo(exists: true,
                                hasWordPress: true,
                                isWordPressCom: false,
                                hasJetpack: true,
                                isJetpackActive: false,
                                isJetpackConnected: false)
        var result: WordPressAuthenticatorResult?
        let completionHandler: (WordPressAuthenticatorResult) -> Void = { completionResult in
            result = completionResult
        }

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: completionHandler)

        // Then
        guard case .presentPasswordController = result else {
            return XCTFail("Unexpected result returned for non-Jetpack site")
        }
    }

    func test_it_shows_account_mismatch_upon_login_epilogue_if_the_site_has_active_jetpack_but_not_connected() {
        // Given
        let manager = AuthenticationManager()
        let testSite = "http://test.com"
        let siteInfo = siteInfo(url: testSite,
                                exists: true,
                                hasWordPress: true,
                                isWordPressCom: false,
                                hasJetpack: true,
                                isJetpackActive: true,
                                isJetpackConnected: false)
        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false, siteURL: testSite)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)
        let navigationController = UINavigationController()

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { _ in })
        manager.presentLoginEpilogue(in: navigationController, for: credentials, source: nil, onDismiss: {})

        // Then
        let rootController = navigationController.viewControllers.first
        XCTAssertTrue(rootController is ULAccountMismatchViewController)
    }

    func test_it_does_not_display_jetpack_error_for_org_site_credentials_sign_in_when_using_application_password_authentication() {
        // Given
        let mockABTestVariationProvider = MockABTestVariationProvider()
        mockABTestVariationProvider.mockVariationValue = .treatment

        let manager = AuthenticationManager(abTestVariationProvider: mockABTestVariationProvider)
        let testSite = "http://test.com"
        let siteInfo = WordPressComSiteInfo(remote: ["isWordPress": true, "hasJetpack": false, "urlAfterRedirects": testSite])
        let wporgCredentials = WordPressOrgCredentials(username: "cba", password: "password", xmlrpc: "http://test.com/xmlrpc.php", options: [:])
        let credentials = AuthenticatorCredentials(wpcom: nil, wporg: wporgCredentials)
        let navigationController = UINavigationController()

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { _ in })
        manager.presentLoginEpilogue(in: navigationController, for: credentials, source: nil, onDismiss: {})

        // Then
        let rootController = navigationController.viewControllers.first
        XCTAssertFalse(rootController is ULErrorViewController)
    }

    func test_errorViewController_display_account_mismatch_screen_if_no_site_matches_the_given_self_hosted_site() {
        // Given
        let manager = AuthenticationManager()
        let testSite = "http://test.com"
        let navigationController = UINavigationController()
        let storage = MockStorageManager()
        let matcher = ULAccountMatcher(storageManager: storage)
        let wporgCredentials = WordPressOrgCredentials(username: "test", password: "pwd", xmlrpc: "http://test.com/xmlrpc.php", options: [:])
        let credentials = AuthenticatorCredentials(wpcom: nil, wporg: wporgCredentials)

        // When
        let controller = manager.errorViewController(for: testSite, with: matcher, credentials: credentials, navigationController: navigationController) {}

        // Then
        XCTAssertNotNil(controller)
        XCTAssertTrue(controller is ULAccountMismatchViewController)
    }

    func test_errorViewController_returns_account_mismatch_if_no_site_matches_the_given_url() {
        // Given
        let manager = AuthenticationManager()
        let testSite = "http://test.com"
        let navigationController = UINavigationController()
        let storage = MockStorageManager()
        let matcher = ULAccountMatcher(storageManager: storage)

        // When
        let controller = manager.errorViewController(for: testSite, with: matcher, navigationController: navigationController) {}

        // Then
        XCTAssertNotNil(controller)
        XCTAssertTrue(controller is ULAccountMismatchViewController)
    }

    func test_errorViewController_returns_error_if_the_given_site_does_not_have_woo() {
        // Given
        let manager = AuthenticationManager()
        let navigationController = UINavigationController()

        let testSiteURL = "http://test.com"
        let testSite = Site.fake().copy(siteID: 1234, name: "Test", url: testSiteURL, isWooCommerceActive: false)

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)
        let matcher = ULAccountMatcher(storageManager: storage)
        matcher.refreshStoredSites()

        // When
        let controller = manager.errorViewController(for: testSiteURL, with: matcher, navigationController: navigationController) {}

        // Then
        XCTAssertNotNil(controller)
        XCTAssertTrue(controller is ULErrorViewController)
    }

    func test_errorViewController_returns_nil_if_the_given_site_has_woo() {
        // Given
        let manager = AuthenticationManager()
        let navigationController = UINavigationController()

        let testSiteURL = "http://test.com"
        let testSite = Site.fake().copy(siteID: 1234, name: "Test", url: testSiteURL, isWooCommerceActive: true)

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)
        let matcher = ULAccountMatcher(storageManager: storage)
        matcher.refreshStoredSites()

        // When
        let controller = manager.errorViewController(for: testSiteURL, with: matcher, navigationController: navigationController) {}

        // Then
        XCTAssertNil(controller)
    }

    func test_site_address_is_saved_to_local_storage_if_there_is_error_with_the_site() {
        // Given
        let navigationController = UINavigationController()

        let testSiteURL = "http://test.com"
        let testSite = Site.fake().copy(siteID: 1234, name: "Test", url: testSiteURL, isWooCommerceActive: false) // No Woo

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)
        let manager = AuthenticationManager(storageManager: storage)
        let settings = MockLoggedOutAppSettings()
        manager.setLoggedOutAppSettings(settings)

        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false, siteURL: testSiteURL)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)

        // When
        manager.presentLoginEpilogue(in: navigationController, for: credentials, source: nil, onDismiss: {})

        // Then
        XCTAssertEqual(settings.errorLoginSiteAddress, testSiteURL)
    }

    func test_site_address_is_cleared_if_there_is_no_error_with_the_site() {
        // Given
        let navigationController = UINavigationController()

        let testSiteURL = "http://test.com"
        let testSite = Site.fake().copy(siteID: 1234, name: "Test", url: testSiteURL, isWooCommerceActive: true)

        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)
        let manager = AuthenticationManager(storageManager: storage)
        let settings = MockLoggedOutAppSettings(errorLoginSiteAddress: "http//:test.com")
        manager.setLoggedOutAppSettings(settings)

        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false, siteURL: testSiteURL)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)

        // When
        manager.presentLoginEpilogue(in: navigationController, for: credentials, source: nil, onDismiss: {})

        // Then
        XCTAssertNil(settings.errorLoginSiteAddress)
    }

    func test_troubleshootSite_displays_error_screen_if_site_does_not_have_wordPress() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: false)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULErrorViewController)
    }

    func test_troubleshootSite_displays_account_mismatch_error_if_site_is_wpcom() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: true)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULAccountMismatchViewController)
    }

    func test_troubleshootSite_displays_error_screen_if_site_is_self_hosted_without_jetpack() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: false, hasJetpack: false)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULErrorViewController)
    }

    func test_troubleshootSite_displays_error_screen_if_site_is_self_hosted_with_jetpack_not_connected() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: false, hasJetpack: true, isJetpackActive: true, isJetpackConnected: false)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULAccountMismatchViewController || topController is ULErrorViewController)
    }

    func test_troubleshootSite_displays_error_screen_if_site_is_self_hosted_with_jetpack() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: false, hasJetpack: true, isJetpackActive: true, isJetpackConnected: true)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULAccountMismatchViewController || topController is ULErrorViewController)
    }

    func test_troubleshootSite_tracks_site_discovery_event() throws {
        // Given
        let navigationController = UINavigationController()
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: true, hasJetpack: true, isJetpackActive: true, isJetpackConnected: true)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage, analytics: analytics)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.sitePickerSiteDiscovery.rawValue])
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["has_wordpress"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_wpcom"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_jetpack_installed"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_jetpack_active"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_jetpack_connected"] as? Bool))
    }

    func test_shouldPresentUsernamePasswordController_tracks_fetched_site_info() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: true, hasJetpack: true, isJetpackActive: true, isJetpackConnected: true)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage, analytics: analytics)

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo) { _ in }

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.loginSiteAddressSiteInfoFetched.rawValue])
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_wordpress"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_wp_com"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["has_jetpack"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_jetpack_active"] as? Bool))
        XCTAssertTrue(try XCTUnwrap(analyticsProvider.receivedProperties.first?["is_jetpack_connected"] as? Bool))
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["url_after_redirects"] as? String, siteInfo.url)
    }

    func test_it_presents_store_creation_flow_when_there_are_no_valid_stores() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isStoreCreationM2Enabled: true,
                                                        isStoreCreationM2WithInAppPurchasesEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let testSite = Site.fake().copy(isWooCommerceActive: false)
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)

        let manager = AuthenticationManager(stores: stores,
                                            storageManager: storage,
                                            featureFlagService: featureFlagService,
                                            purchasesManager: MockInAppPurchases(fetchProductsDuration: 0))

        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)

        // When
        manager.presentLoginEpilogue(in: navigationController,
                                     for: credentials,
                                     source: SignInSource.custom(source: LoggedOutStoreCreationCoordinator.Source.prologue.rawValue),
                                     onDismiss: {})

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is StoreNameFormHostingController
        }
    }
}

private extension AuthenticationManagerTests {
    func siteInfo(url: String = "https://test.com",
                  exists: Bool = false,
                  hasWordPress: Bool = false,
                  isWordPressCom: Bool = false,
                  hasJetpack: Bool = false,
                  isJetpackActive: Bool = false,
                  isJetpackConnected: Bool = false) -> WordPressComSiteInfo {
        WordPressComSiteInfo(remote: ["urlAfterRedirects": url,
                                      "exists": exists,
                                      "isWordPress": hasWordPress,
                                      "hasJetpack": hasJetpack,
                                      "isJetpackActive": isJetpackActive,
                                      "isJetpackConnected": isJetpackConnected,
                                      "isWordPressDotCom": isWordPressCom])
    }
}
