import XCTest
@testable import WooCommerce
import WordPressAuthenticator
import Yosemite
import enum Alamofire.AFError

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
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", stores: stores)
        XCTAssertFalse(viewModel.isLoggingIn)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
    }

    func test_isLoggingIn_is_updated_appropriately_when_login_succeeds() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", stores: stores)
        XCTAssertFalse(viewModel.isLoggingIn)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(SitePlugin.fake()))
            default:
                break
            }
        }
        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
    }

    func test_shouldShowErrorAlert_is_true_when_login_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", stores: stores)
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = NSError(domain: "Test", code: 1)
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.genericFailure)
    }

    func test_errorMessage_is_correct_when_login_fails_with_incorrect_credentials() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", stores: stores)
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.wrongCredentials)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_succeeds() {
        // Given
        var successHandlerTriggered = false
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores) {
            successHandlerTriggered = true
        }
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(SitePlugin.fake()))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.shouldShowErrorAlert)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_fails_with_404() {
        // Given
        var successHandlerTriggered = false
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores) {
            successHandlerTriggered = true
        }
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.shouldShowErrorAlert)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_fails_with_403() {
        // Given
        var successHandlerTriggered = false
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores) {
            successHandlerTriggered = true
        }
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.shouldShowErrorAlert)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
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
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores, analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(MockError()))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_did_show_error_alert" }))
    }

    func test_it_tracks_login_jetpack_site_credential_did_finish_login_when_login_finishes() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, stores: stores, analytics: analytics)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(SitePlugin.fake()))
            default:
                break
            }
        }

        // When
        viewModel.handleLogin()

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
