import XCTest
@testable import WooCommerce
import WordPressAuthenticator
import Yosemite

final class SiteCredentialLoginViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        // There is no known tear down for the Authenticator. So this method intentionally does
        // nothing.
        super.tearDown()
    }

    func test_primary_button_is_disabled_appropriately() {
        // Given
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        XCTAssertTrue(viewModel.primaryButtonDisabled)

        // When
        viewModel.username = "test"

        // Then
        XCTAssertTrue(viewModel.primaryButtonDisabled)

        // When
        viewModel.password = "secret"

        // Then
        XCTAssertFalse(viewModel.primaryButtonDisabled)
    }

    func test_isLoggingIn_is_updated_appropriately_when_login_fails() {
        // Given
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        XCTAssertFalse(viewModel.isLoggingIn)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.isLoggingIn)

        // When
        viewModel.displayRemoteError(NSError(domain: "Test", code: 1))

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
    }

    func test_isLoggingIn_is_updated_appropriately_when_login_succeeds() {
        // Given
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        XCTAssertFalse(viewModel.isLoggingIn)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.isLoggingIn)

        // When
        viewModel.finishedLogin(withUsername: "test", password: "secret", xmlrpc: "abcxyz")

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
    }

    func test_shouldShowErrorAlert_is_true_when_login_fails() {
        // Given
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        viewModel.displayRemoteError(NSError(domain: "Test", code: 1))

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.genericFailure)
    }

    func test_errorMessage_is_correct_when_login_fails_with_incorrect_credentials() {
        // Given
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        viewModel.displayRemoteError(NSError(domain: "WPXMLRPCFaultError", code: 403))

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.wrongCredentials)
    }

    func test_finishedLogin_triggers_authentication_in_JetpackConnectionAction_and_successHandler() {
        // Given
        var successHandlerTriggered = false
        var returnedXMLRPC: String?
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let xmlrpcURL = "https://test.com/xmlrpc.php"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores) { xmlrpc in
            successHandlerTriggered = true
            returnedXMLRPC = xmlrpc
        }
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            default:
                break
            }
        }

        // When
        viewModel.finishedLogin(withUsername: "test", password: "secret", xmlrpc: xmlrpcURL)

        // Then
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
        XCTAssertEqual(returnedXMLRPC, xmlrpcURL)
    }

    // MARK: - Analytics
    func test_it_tracks_login_jetpack_site_credential_install_button_tapped_when_tapping_install_button() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_install_button_tapped" }))
    }

    func test_it_tracks_login_jetpack_site_credential_reset_password_button_tapped_when_tapping_reset_password_button() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics)

        // When
        viewModel.resetPassword()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_reset_password_button_tapped" }))
    }

    func test_it_tracks_login_jetpack_site_credential_did_show_error_alert_when_displaying_remote_error() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics)

        // When
        viewModel.displayRemoteError(MockError())

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_did_show_error_alert" }))
    }

    func test_it_tracks_login_jetpack_site_credential_did_finish_login_when_login_finishes() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics)

        // When
        viewModel.finishedLogin(withUsername: "", password: "", xmlrpc: "")

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_did_finish_login" }))
    }
}

private extension SiteCredentialLoginViewModelTests {
    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}
