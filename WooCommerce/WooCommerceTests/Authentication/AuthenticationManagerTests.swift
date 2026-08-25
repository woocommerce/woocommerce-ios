import TestKit
import XCTest
@testable import Networking
@testable import NetworkingCore
import WordPressAuthenticator
import WordPressUI
import Yosemite
import YosemiteTestHelpers
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

    func test_application_password_factory_receives_custom_endpoints_from_wordpress_org_credentials() throws {
        // Given
        let apiRoot = "https://example.com/wp-json/"
        WordPressRESTAPIRootCache.shared.setRoot(apiRoot, for: "https://example.com")
        defer { WordPressRESTAPIRootCache.shared.removeRoot(apiRoot, for: "https://example.com") }
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "password",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: [
                "login_url": ["value": "https://example.com/custom-login"],
                "admin_url": ["value": "https://example.com/custom-admin"]
            ]
        )
        var capturedUsername: String?
        var capturedPassword: String?
        var capturedSiteAddress: String?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let manager = AuthenticationManager(
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { username, password, siteAddress, endpoints in
                capturedUsername = username
                capturedPassword = password
                capturedSiteAddress = siteAddress
                capturedEndpoints = endpoints
                return MockAuthenticationManagerApplicationPasswordUseCase()
            })
        )

        // When
        _ = try manager.makeApplicationPasswordUseCase(for: credentials)

        // Then
        XCTAssertEqual(capturedUsername, "merchant")
        XCTAssertEqual(capturedPassword, "password")
        XCTAssertEqual(capturedSiteAddress, "https://example.com")
        XCTAssertEqual(capturedEndpoints?.siteURL.absoluteString, "https://example.com")
        XCTAssertEqual(capturedEndpoints?.loginEntryURL.absoluteString, "https://example.com/custom-login")
        XCTAssertEqual(capturedEndpoints?.adminBaseURL.absoluteString, "https://example.com/custom-admin/")
    }

    func test_site_credential_login_factory_receives_custom_endpoints_from_wordpress_org_credentials() {
        // Given
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "password",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: [
                "login_url": ["value": "https://example.com/custom-login"],
                "admin_url": ["value": "https://example.com/custom-admin"]
            ]
        )
        let mockUseCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var capturedSiteURL: String?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let manager = AuthenticationManager(
            siteCredentialLoginUseCaseFactory: { siteURL, endpoints, _ in
                capturedSiteURL = siteURL
                capturedEndpoints = endpoints
                return mockUseCase
            }
        )

        // When
        manager.handleSiteCredentialLogin(
            credentials: credentials,
            onLoading: { _ in },
            onSuccess: {},
            onFailure: { _, _ in }
        )

        // Then
        XCTAssertEqual(capturedSiteURL, "https://example.com")
        XCTAssertEqual(capturedEndpoints?.siteURL.absoluteString, "https://example.com")
        XCTAssertEqual(capturedEndpoints?.loginEntryURL.absoluteString, "https://example.com/custom-login")
        XCTAssertEqual(capturedEndpoints?.adminBaseURL.absoluteString, "https://example.com/custom-admin/")
        XCTAssertEqual(mockUseCase.receivedUsername, "merchant")
        XCTAssertEqual(mockUseCase.receivedPassword, "password")
    }

    func test_application_password_factory_receives_nil_endpoints_when_credential_options_are_malformed() throws {
        // Given
        let apiRoot = "https://example.com/wp-json/"
        WordPressRESTAPIRootCache.shared.setRoot(apiRoot, for: "https://example.com")
        defer { WordPressRESTAPIRootCache.shared.removeRoot(apiRoot, for: "https://example.com") }
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "password",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: ["login_url": ["value": ":// malformed"]]
        )
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let manager = AuthenticationManager(
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { _, _, _, endpoints in
                capturedEndpoints = endpoints
                return MockAuthenticationManagerApplicationPasswordUseCase()
            })
        )

        // When
        _ = try manager.makeApplicationPasswordUseCase(for: credentials)

        // Then
        XCTAssertNil(capturedEndpoints)
    }

    func test_sync_when_native_wporg_credentials_are_custom_default_or_malformed_then_injects_exact_boundary_endpoints() throws {
        let cases: [(options: [String: Any], expectedLogin: String?, expectedAdmin: String?)] = [
            (
                options: [
                    "login_url": ["value": "https://example.com/custom-login"],
                    "admin_url": ["value": "https://example.com/private-admin"]
                ],
                expectedLogin: "https://example.com/custom-login",
                expectedAdmin: "https://example.com/private-admin/"
            ),
            (
                options: [:],
                expectedLogin: "https://example.com/wp-login.php",
                expectedAdmin: "https://example.com/wp-admin/"
            ),
            (
                options: ["login_url": ["value": ":// malformed"]],
                expectedLogin: nil,
                expectedAdmin: nil
            )
        ]

        for testCase in cases {
            // Given
            let sessionManager = SessionManager(
                defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
                keychainServiceName: UUID().uuidString
            )
            let stores = MockStoresManager(sessionManager: sessionManager)
            let manager = AuthenticationManager(stores: stores)
            let wporg = WordPressOrgCredentials(
                username: "Merchant",
                password: "password",
                xmlrpc: "https://example.com/xmlrpc.php",
                options: testCase.options
            )
            var didComplete = false

            // When
            manager.sync(credentials: AuthenticatorCredentials(wpcom: nil, wporg: wporg)) {
                didComplete = true
            }

            // Then
            XCTAssertTrue(didComplete)
            XCTAssertEqual(
                stores.authenticatedCredentials,
                .wporg(username: "Merchant", password: "password", siteAddress: "https://example.com")
            )
            XCTAssertEqual(stores.authenticatedCookieNonceAuthenticationEndpoints?.siteURL.absoluteString,
                           testCase.expectedLogin == nil ? nil : "https://example.com")
            XCTAssertEqual(stores.authenticatedCookieNonceAuthenticationEndpoints?.loginEntryURL.absoluteString,
                           testCase.expectedLogin)
            XCTAssertEqual(stores.authenticatedCookieNonceAuthenticationEndpoints?.adminBaseURL.absoluteString,
                           testCase.expectedAdmin)
        }
    }

    func test_did_authenticate_user_applies_custom_default_and_malformed_endpoint_context_through_real_checker() throws {
        let cases: [(options: [String: Any], expectedStoredEndpoint: String?)] = [
            (
                options: [
                    "login_url": ["value": "https://example.com/custom-login"],
                    "admin_url": ["value": "https://example.com/private-admin"]
                ],
                expectedStoredEndpoint: "https://example.com/custom-login"
            ),
            (options: [:], expectedStoredEndpoint: nil),
            (options: ["login_url": ["value": ":// malformed"]], expectedStoredEndpoint: "https://example.com/stale-login")
        ]

        for testCase in cases {
            // Given
            let sessionManager = SessionManager(
                defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
                keychainServiceName: UUID().uuidString
            )
            let stores = MockStoresManager(sessionManager: sessionManager)
            let credentials: Credentials = .wporg(
                username: "merchant",
                password: "password",
                siteAddress: "https://example.com"
            )
            let staleEndpoints = try CookieNonceAuthenticationEndpoints(
                siteURL: XCTUnwrap(URL(string: "https://example.com")),
                loginEntryURL: XCTUnwrap(URL(string: "https://example.com/stale-login")),
                adminBaseURL: XCTUnwrap(URL(string: "https://example.com/stale-admin/"))
            )
            sessionManager.saveCookieNonceAuthenticationEndpoints(staleEndpoints, for: credentials)
            let applicationPassword = ApplicationPassword(
                wpOrgUsername: "merchant",
                password: .init("application-password"),
                uuid: UUID().uuidString
            )
            let manager = AuthenticationManager(
                stores: stores,
                applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { _, _, _, _ in
                    MockAuthenticationManagerApplicationPasswordUseCase(applicationPassword: applicationPassword)
                })
            )
            let wporg = WordPressOrgCredentials(
                username: "merchant",
                password: "password",
                xmlrpc: "https://example.com/xmlrpc.php",
                options: testCase.options
            )

            // When
            manager.didAuthenticateUser(to: "https://example.com", with: wporg, in: navigationController)

            // Then
            XCTAssertEqual(
                sessionManager.cookieNonceAuthenticationEndpoints(for: credentials)?.loginEntryURL.absoluteString,
                testCase.expectedStoredEndpoint
            )
        }
    }

    func test_browser_application_password_maps_to_application_password_credentials() {
        // Given
        let applicationPassword = ApplicationPassword(
            wpOrgUsername: "merchant",
            password: .init("application-password"),
            uuid: UUID().uuidString
        )

        // When
        let credentials = AuthenticationManager.credentials(
            for: applicationPassword,
            siteURL: "https://example.com"
        )

        // Then
        XCTAssertEqual(
            credentials,
            .applicationPassword(username: "merchant", password: "application-password", siteAddress: "https://example.com")
        )
    }

    func test_application_password_factory_when_credentials_are_fresh_then_clears_site_cookies_before_construction() throws {
        // Given
        let runtimeCookieJar = MockCookieJar()
        let siteCookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: ".example.com",
            .path: "/",
            .secure: true,
            .name: "wordpress_logged_in_stale",
            .value: "wrong-user"
        ]))
        let unrelatedCookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: "unrelated.test",
            .path: "/",
            .name: "unrelated-session",
            .value: "preserve"
        ]))
        runtimeCookieJar.setCookie(siteCookie)
        runtimeCookieJar.setCookie(unrelatedCookie)
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "password",
            xmlrpc: "http://shop.example.com/xmlrpc.php",
            options: [:]
        )
        var cookieNamesDuringConstruction = Set<String>()
        let manager = AuthenticationManager(
            runtimeCookieJar: runtimeCookieJar,
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { _, _, _, _ in
                cookieNamesDuringConstruction = Set(runtimeCookieJar.cookies?.map(\.name) ?? [])
                return MockAuthenticationManagerApplicationPasswordUseCase()
            })
        )

        // When
        _ = try manager.makeApplicationPasswordUseCase(for: credentials)

        // Then
        XCTAssertFalse(cookieNamesDuringConstruction.contains(siteCookie.name))
        XCTAssertTrue(cookieNamesDuringConstruction.contains(unrelatedCookie.name))
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

    func test_it_presents_email_controller_for_commerce_garden_site() {
        // Given
        let manager = AuthenticationManager()
        let siteInfo = siteInfo(exists: true,
                                hasWordPress: true,
                                isWordPressCom: false,
                                isCommerceGarden: true,
                                hasJetpack: true,
                                isJetpackActive: true,
                                isJetpackConnected: false)
        var result: WordPressAuthenticatorResult?
        let completionHandler: (WordPressAuthenticatorResult) -> Void = { completionResult in
            result = completionResult
        }

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: completionHandler)

        // Then
        guard case .presentEmailController = result else {
            return XCTFail("Expected presentEmailController for Commerce Garden site")
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
            navigationController.viewControllers.isNotEmpty &&
            navigationController.topViewController != nil
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

    func test_troubleshootSite_displays_account_mismatch_error_if_site_is_commerce_garden() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: false, isCommerceGarden: true)
        let storage = MockStorageManager()
        let manager = AuthenticationManager(storageManager: storage)

        // When
        manager.troubleshootSite(siteInfo, in: navigationController)

        // Then
        waitUntil {
            navigationController.viewControllers.isNotEmpty &&
            navigationController.topViewController != nil
        }
        let topController = navigationController.topViewController
        XCTAssertTrue(topController is ULAccountMismatchViewController)
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

    func test_it_auto_switches_store_when_there_is_only_one_valid_store() throws {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        let stores = MockStoresManager(sessionManager: sessionManager)

        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let testSite = Site.fake().copy(siteID: 123, isWooCommerceActive: true)
        let storage = MockStorageManager()
        storage.insertSampleSite(readOnlySite: testSite)

        let switchStoreUseCase = MockSwitchStoreUseCase()
        let manager = AuthenticationManager(stores: stores,
                                            storageManager: storage,
                                            switchStoreUseCase: switchStoreUseCase)

        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)

        // When
        manager.presentLoginEpilogue(in: navigationController,
                                     for: credentials,
                                     source: SignInSource.wpCom,
                                     onDismiss: {
            // Then
            XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [123])
        })
    }

    func test_it_does_not_auto_select_store_when_there_are_more_than_one_only_one_valid_stores() throws {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        let stores = MockStoresManager(sessionManager: sessionManager)

        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let storage = MockStorageManager()

        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: 123, isWooCommerceActive: true))
        storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: 124, isWooCommerceActive: true))

        let switchStoreUseCase = MockSwitchStoreUseCase()
        let manager = AuthenticationManager(stores: stores,
                                            storageManager: storage,
                                            switchStoreUseCase: switchStoreUseCase)

        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)

        // When
        manager.presentLoginEpilogue(in: navigationController,
                                     for: credentials,
                                     source: SignInSource.wpCom,
                                     onDismiss: {
            // Then
            XCTAssertEqual(switchStoreUseCase.destinationStoreIDs, [])
        })
    }

    func test_authenticate_site_credentials_when_login_url_is_cross_site_then_recovers_without_starting_login() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let manager = AuthenticationManager(
            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
            siteCredentialLoginUseCaseFactory: { _, _, _ in
                XCTFail("Login must not start for a locally rejected endpoint")
                return MockAuthenticationManagerSiteCredentialLoginUseCase()
            }
        )
        var loading = [Bool]()
        var recovery: SiteCredentialRecovery?

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://attacker.example/wp-login.php",
            adminURL: nil,
            endpointUnderVerification: .login,
            onLoading: { loading.append($0) },
            onSuccess: { _ in XCTFail("Expected endpoint recovery") },
            onRecovery: { recovery = $0 },
            onFailure: { _, _, _, _ in XCTFail("Expected endpoint recovery") }
        )

        // Then
        XCTAssertEqual(
            recovery,
            .login(draftURL: "https://attacker.example/wp-login.php", error: .differentSite)
        )
        XCTAssertTrue(loading.isEmpty)
        XCTAssertTrue(analyticsProvider.receivedEvents.isEmpty)
    }

    func test_authenticate_site_credentials_when_network_failure_surfaces_recovery_then_does_not_track_login_failure() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        let manager = AuthenticationManager(
            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
            siteCredentialLoginUseCaseFactory: { _, _, _ in useCase }
        )

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: nil,
            adminURL: nil,
            endpointUnderVerification: nil,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected endpoint recovery") },
            onRecovery: { _ in },
            onFailure: { _, _, _, _ in XCTFail("Expected endpoint recovery") }
        )
        useCase.fail(with: .inaccessibleLoginPage, loginEntryVerified: false)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.loginSiteCredentialsFailed.rawValue))
    }

    func test_authenticate_site_credentials_when_genuine_failure_occurs_then_tracks_login_failure() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        let manager = AuthenticationManager(
            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
            siteCredentialLoginUseCaseFactory: { _, _, _ in useCase }
        )

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: nil,
            adminURL: nil,
            endpointUnderVerification: nil,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected failure") },
            onRecovery: { _ in XCTFail("Expected failure") },
            onFailure: { _, _, _, _ in }
        )
        useCase.fail(with: .invalidCredentials, loginEntryVerified: true)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.loginSiteCredentialsFailed.rawValue))
    }

    func test_authenticate_site_credentials_when_login_retry_is_missing_then_recovers_not_found_after_loading_starts() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var events = [String]()
        useCase.onHandleLogin = { events.append("handle") }
        var verifyAdminDashboard: Bool?
        var recovery: SiteCredentialRecovery?
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, verifyAdmin in
            verifyAdminDashboard = verifyAdmin
            return useCase
        })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://example.com/custom-login",
            adminURL: nil,
            endpointUnderVerification: .login,
            onLoading: { events.append("loading:\($0)") },
            onSuccess: { _ in XCTFail("Expected endpoint recovery") },
            onRecovery: {
                recovery = $0
                events.append("recovery")
            },
            onFailure: { _, _, _, _ in XCTFail("Expected endpoint recovery") }
        )
        useCase.fail(with: .inaccessibleLoginPage, loginEntryVerified: false)

        // Then
        XCTAssertEqual(verifyAdminDashboard, false)
        XCTAssertEqual(useCase.receivedUsername, "merchant")
        XCTAssertEqual(useCase.receivedPassword, "password")
        XCTAssertEqual(recovery, .login(draftURL: "https://example.com/custom-login", error: .notFound))
        XCTAssertEqual(events, ["loading:true", "handle", "loading:false", "recovery"])
    }

    func test_authenticate_site_credentials_when_login_retry_has_invalid_unverified_response_then_recovers_not_found() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var recovery: SiteCredentialRecovery?
        var didFail = false
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, _ in useCase })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://example.com/custom-login",
            adminURL: nil,
            endpointUnderVerification: .login,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected recovery") },
            onRecovery: { recovery = $0 },
            onFailure: { _, _, _, _ in didFail = true }
        )
        useCase.fail(with: .invalidLoginResponse, loginEntryVerified: false)

        // Then
        XCTAssertEqual(
            recovery,
            .login(draftURL: "https://example.com/custom-login", error: .notFound)
        )
        XCTAssertFalse(didFail)
    }

    func test_authenticate_site_credentials_when_initial_login_has_invalid_unverified_response_then_recovers_without_error() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var recovery: SiteCredentialRecovery?
        var didFail = false
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, _ in useCase })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: nil,
            adminURL: nil,
            endpointUnderVerification: nil,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected recovery") },
            onRecovery: { recovery = $0 },
            onFailure: { _, _, _, _ in didFail = true }
        )
        useCase.fail(with: .invalidLoginResponse, loginEntryVerified: false)

        // Then
        XCTAssertEqual(
            recovery,
            .login(draftURL: "https://example.com/wp-login.php", error: nil)
        )
        XCTAssertFalse(didFail)
    }

    func test_authenticate_site_credentials_when_admin_is_missing_after_verified_custom_login_then_recovers_admin() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var endpoints: CookieNonceAuthenticationEndpoints?
        var verifyAdminDashboard: Bool?
        var recovery: SiteCredentialRecovery?
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, receivedEndpoints, verifyAdmin in
            endpoints = receivedEndpoints
            verifyAdminDashboard = verifyAdmin
            return useCase
        })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://example.com/custom-login#fragment",
            adminURL: nil,
            endpointUnderVerification: .login,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected endpoint recovery") },
            onRecovery: { recovery = $0 },
            onFailure: { _, _, _, _ in XCTFail("Expected endpoint recovery") }
        )
        useCase.fail(with: .inaccessibleAdminPage, loginEntryVerified: true)

        // Then
        XCTAssertEqual(endpoints?.loginEntryURL.absoluteString, "https://example.com/custom-login")
        XCTAssertEqual(verifyAdminDashboard, false)
        XCTAssertEqual(
            recovery,
            .admin(
                verifiedLoginURL: "https://example.com/custom-login",
                draftURL: "https://example.com/wp-admin/",
                error: nil
            )
        )
    }

    func test_authenticate_site_credentials_when_admin_retry_login_preflight_fails_then_routes_to_ordinary_failure() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var verifyAdminDashboard: Bool?
        var receivedError: Error?
        var incorrectCredentials: Bool?
        var verifiedLoginURL: String?
        var didRecover = false
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, verifyAdmin in
            verifyAdminDashboard = verifyAdmin
            return useCase
        })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://example.com/custom-login",
            adminURL: "https://example.com/private-admin",
            endpointUnderVerification: .admin,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected failure") },
            onRecovery: { _ in didRecover = true },
            onFailure: { error, isIncorrectCredentials, loginURL, _ in
                receivedError = error
                incorrectCredentials = isIncorrectCredentials
                verifiedLoginURL = loginURL
            }
        )
        useCase.fail(with: .inaccessibleLoginPage, loginEntryVerified: false)

        // Then
        XCTAssertEqual(verifyAdminDashboard, true)
        if case .inaccessibleLoginPage? = receivedError as? SiteCredentialLoginError {} else {
            XCTFail("Expected inaccessible login page failure")
        }
        XCTAssertEqual(incorrectCredentials, false)
        XCTAssertNil(verifiedLoginURL)
        XCTAssertFalse(didRecover)
    }

    func test_authenticate_site_credentials_when_verified_credentials_are_invalid_then_marks_incorrect_and_preserves_login_url() {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var incorrectCredentials: Bool?
        var verifiedLoginURL: String?
        var offersBrowserAlternative: Bool?
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, _ in useCase })

        // When
        manager.authenticateSiteCredentials(
            credentials: siteCredentials(),
            loginURL: "https://example.com/custom-login",
            adminURL: nil,
            endpointUnderVerification: .login,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected failure") },
            onRecovery: { _ in XCTFail("Expected ordinary failure") },
            onFailure: {
                incorrectCredentials = $1
                verifiedLoginURL = $2
                offersBrowserAlternative = $3
            }
        )
        useCase.fail(with: .invalidCredentials, loginEntryVerified: true, offersBrowserAlternative: true)

        // Then
        XCTAssertEqual(incorrectCredentials, true)
        XCTAssertEqual(verifiedLoginURL, "https://example.com/custom-login")
        XCTAssertEqual(offersBrowserAlternative, true)
    }

    func test_present_site_credential_login_failure_presents_centered_fancy_alert() throws {
        // Given
        let presenter = SiteCredentialAlertPresenter()
        navigationController.setViewControllers([presenter], animated: false)
        let manager = AuthenticationManager()

        // When
        manager.presentSiteCredentialLoginFailure(
            error: SiteCredentialLoginError.invalidCredentials,
            offersBrowserAlternative: false,
            for: "https://example.com",
            in: presenter
        )

        // Then
        try assertCenteredFancyAlertPresented(by: presenter)
    }

    func test_present_site_credential_browser_alternative_presents_tutorial_without_tracking_invalid_login_page() {
        // Given
        let presenter = UIViewController()
        navigationController.setViewControllers([presenter], animated: false)
        let analyticsProvider = MockAnalyticsProvider()
        let manager = AuthenticationManager(analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        manager.presentSiteCredentialBrowserAlternative(for: "https://example.com", in: presenter)

        // Then
        XCTAssertTrue(navigationController.topViewController is ApplicationPasswordTutorialViewController)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.loginSiteCredentialsInvalidLoginPageDetected.rawValue))
    }

    func test_handle_site_credential_login_failure_when_invalid_login_page_is_detected_then_tracks_detection() {
        // Given
        let presenter = UIViewController()
        navigationController.setViewControllers([presenter], animated: false)
        let analyticsProvider = MockAnalyticsProvider()
        let manager = AuthenticationManager(analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        manager.handleSiteCredentialLoginFailure(
            error: SiteCredentialLoginError.inaccessibleLoginPage,
            for: "https://example.com",
            in: presenter
        )

        // Then
        XCTAssertTrue(navigationController.topViewController is ApplicationPasswordTutorialViewController)
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.loginSiteCredentialsInvalidLoginPageDetected.rawValue))
    }

    func test_legacy_site_credential_login_failure_presents_centered_fancy_alert() throws {
        // Given
        let presenter = SiteCredentialAlertPresenter()
        navigationController.setViewControllers([presenter], animated: false)
        let manager = AuthenticationManager()

        // When
        manager.handleSiteCredentialLoginFailure(
            error: SiteCredentialLoginError.invalidCredentials,
            for: "https://example.com",
            in: presenter
        )

        // Then
        try assertCenteredFancyAlertPresented(by: presenter)
    }

    func test_authenticate_site_credentials_when_custom_or_standard_login_succeeds_then_persists_only_nondefault_endpoints() throws {
        // Given
        let useCase = MockAuthenticationManagerSiteCredentialLoginUseCase()
        var receivedCredentials: WordPressOrgCredentials?
        var loading = [Bool]()
        let manager = AuthenticationManager(siteCredentialLoginUseCaseFactory: { _, _, _ in useCase })
        let credentials = siteCredentials(options: [
            "login_url": ["value": "https://example.com/stale-login"],
            "admin_url": ["value": "https://example.com/stale-admin"],
            "unrelated": ["value": "preserved"]
        ])

        // When
        manager.authenticateSiteCredentials(
            credentials: credentials,
            loginURL: "https://example.com/custom-login#fragment",
            adminURL: "https://example.com/wp-admin/",
            endpointUnderVerification: .admin,
            onLoading: { loading.append($0) },
            onSuccess: { receivedCredentials = $0 },
            onRecovery: { _ in XCTFail("Expected success") },
            onFailure: { _, _, _, _ in XCTFail("Expected success") }
        )
        useCase.succeed()

        // Then
        let options = try XCTUnwrap(receivedCredentials?.options)
        XCTAssertEqual((options["login_url"] as? [String: String])?["value"], "https://example.com/custom-login")
        XCTAssertNil(options["admin_url"])
        XCTAssertEqual((options["unrelated"] as? [String: String])?["value"], "preserved")
        XCTAssertEqual(loading, [true, false])

        let defaultEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com"))
        )
        let defaultOptions = credentials.replacingAuthenticationEndpoints(with: defaultEndpoints).options
        XCTAssertNil(defaultOptions["login_url"])
        XCTAssertNil(defaultOptions["admin_url"])
        XCTAssertEqual((defaultOptions["unrelated"] as? [String: String])?["value"], "preserved")
    }
}

private extension AuthenticationManagerTests {
    func assertCenteredFancyAlertPresented(by presenter: SiteCredentialAlertPresenter) throws {
        let alert = try XCTUnwrap(presenter.presentedViewController as? FancyAlertViewController)
        XCTAssertEqual(alert.modalPresentationStyle, .custom)
        XCTAssertTrue(alert.transitioningDelegate === presenter)
        XCTAssertTrue(alert.presentationController is FancyAlertPresentationController)
    }

    func siteCredentials(options: [AnyHashable: Any] = [:]) -> WordPressOrgCredentials {
        WordPressOrgCredentials(
            username: "merchant",
            password: "password",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: options
        )
    }

    func siteInfo(url: String = "https://test.com",
                  exists: Bool = false,
                  hasWordPress: Bool = false,
                  isWordPressCom: Bool = false,
                  isCommerceGarden: Bool = false,
                  hasJetpack: Bool = false,
                  isJetpackActive: Bool = false,
                  isJetpackConnected: Bool = false) -> WordPressComSiteInfo {
        WordPressComSiteInfo(remote: ["urlAfterRedirects": url,
                                      "exists": exists,
                                      "isWordPress": hasWordPress,
                                      "hasJetpack": hasJetpack,
                                      "isJetpackActive": isJetpackActive,
                                      "isJetpackConnected": isJetpackConnected,
                                      "isWordPressDotCom": isWordPressCom,
                                      "isCommerceGarden": isCommerceGarden])
    }
}

private final class SiteCredentialAlertPresenter: UIViewController, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

private final class MockAuthenticationManagerSiteCredentialLoginUseCase: SiteCredentialLoginProtocol {
    var onHandleLogin: (() -> Void)?
    private(set) var receivedUsername: String?
    private(set) var receivedPassword: String?
    private var successHandler: (() -> Void)?
    private var failureHandler: ((SiteCredentialLoginError, Bool, Bool) -> Void)?

    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError, Bool, Bool) -> Void) {
        successHandler = onLoginSuccess
        failureHandler = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        receivedUsername = username
        receivedPassword = password
        onHandleLogin?()
    }

    func succeed() {
        successHandler?()
    }

    func fail(with error: SiteCredentialLoginError,
              loginEntryVerified: Bool,
              offersBrowserAlternative: Bool = false) {
        failureHandler?(error, loginEntryVerified, offersBrowserAlternative)
    }
}

private final class MockAuthenticationManagerApplicationPasswordUseCase: ApplicationPasswordUseCase {
    let applicationPassword: ApplicationPassword?
    var canRegenerateApplicationPassword: Bool { true }

    init(applicationPassword: ApplicationPassword? = nil) {
        self.applicationPassword = applicationPassword
    }

    func generateNewPassword() async throws -> ApplicationPassword {
        throw ApplicationPasswordUseCaseError.notSupported
    }

    func deletePassword(locally: Bool) async throws {}
}
