import XCTest
import WordPressKit
import WordPressAuthenticator
import Yosemite
@testable import WooCommerce

/// Test cases for `AuthenticationManager`.
final class AuthenticationManagerTests: XCTestCase {
    /// We do not allow automatic WPCOM account sign-up if the user entered an email that is not
    /// registered in WordPress.com. This configuration is set up in
    /// `WordPressAuthenticatorConfiguration` in `AuthenticationManager.initialize()`.
    func test_it_supports_handling_for_unknown_WPCOM_user_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: WordPressComRestApiError.unknown.rawValue, userInfo: [
            WordPressComRestApi.ErrorKeyErrorCode: "unknown_user"
        ])

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_does_not_support_handling_for_unknown_REST_API_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: WordPressComRestApiError.unknown.rawValue, userInfo: [
            WordPressComRestApi.ErrorKeyErrorCode: "rick_rolled"
        ])

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertFalse(canHandle)
    }

    /// We provide a custom UI for sites that do not seem to be a WordPress site.
    func test_it_supports_handling_for_unknown_site_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: WordPressOrgXMLRPCValidatorError.invalid.rawValue)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
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
        let error = NSError(domain: "", code: WordPressComRestApiError.unknown.rawValue, userInfo: [
            WordPressComRestApi.ErrorKeyErrorCode: "unknown_user"
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

    func test_it_presents_username_and_password_controller_for_non_jetpack_site() {
        // Given
        let manager = AuthenticationManager()
        let siteInfo = WordPressComSiteInfo(remote: ["isWordPress": true, "hasJetpack": false])
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

    func test_it_shows_error_upon_login_epilogue_if_the_self_hosted_site_does_not_have_jetpack() {
        // Given
        let manager = AuthenticationManager()
        let testSite = "http://test.com"
        let siteInfo = WordPressComSiteInfo(remote: ["isWordPress": true, "hasJetpack": false, "urlAfterRedirects": testSite])
        let wpcomCredentials = WordPressComCredentials(authToken: "abc", isJetpackLogin: false, multifactor: false, siteURL: testSite)
        let credentials = AuthenticatorCredentials(wpcom: wpcomCredentials, wporg: nil)
        let navigationController = UINavigationController()

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { _ in })
        manager.presentLoginEpilogue(in: navigationController, for: credentials, onDismiss: {})

        // Then
        let rootController = navigationController.viewControllers.first
        XCTAssertTrue(rootController is ULErrorViewController)
    }

    func test_it_can_display_jetpack_error_for_org_site_credentials_sign_in() {
        // Given
        let manager = AuthenticationManager()
        let testSite = "http://test.com"
        let siteInfo = WordPressComSiteInfo(remote: ["isWordPress": true, "hasJetpack": false, "urlAfterRedirects": testSite])
        let wporgCredentials = WordPressOrgCredentials(username: "cba", password: "password", xmlrpc: "http://test.com/xmlrpc.php", options: [:])
        let credentials = AuthenticatorCredentials(wpcom: nil, wporg: wporgCredentials)
        let navigationController = UINavigationController()

        // When
        manager.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { _ in })
        manager.presentLoginEpilogue(in: navigationController, for: credentials, onDismiss: {})

        // Then
        let rootController = navigationController.viewControllers.first
        XCTAssertTrue(rootController is ULErrorViewController)
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
        manager.presentLoginEpilogue(in: navigationController, for: credentials, onDismiss: {})

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
        manager.presentLoginEpilogue(in: navigationController, for: credentials, onDismiss: {})

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

    func test_troubleshootSite_displays_account_mismatch_screen_if_site_is_self_hosted_with_jetpack() {
        // Given
        let navigationController = UINavigationController()
        let siteInfo = siteInfo(exists: true, hasWordPress: true, isWordPressCom: false, hasJetpack: true)
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
}

private extension AuthenticationManagerTests {
    func siteInfo(exists: Bool = false, hasWordPress: Bool = false, isWordPressCom: Bool = false, hasJetpack: Bool = false) -> WordPressComSiteInfo {
        WordPressComSiteInfo(remote: ["exists": exists,
                                      "isWordPress": hasWordPress,
                                      "hasJetpack": hasJetpack,
                                      "isJetpackActive": hasJetpack,
                                      "isJetpackConnected": hasJetpack,
                                      "isWordPressDotCom": isWordPressCom])
    }
}
