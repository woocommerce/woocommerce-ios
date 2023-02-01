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

    func test_isLoggingIn_is_updated_appropriately_when_the_useCase_returns_true_for_loading_state() {
        // Given
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.mockedLoadingState = true
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", useCase: useCase)
        XCTAssertFalse(viewModel.isLoggingIn)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.isLoggingIn)
    }

    func test_isLoggingIn_is_updated_appropriately_when_the_useCase_returns_false_for_loading_state() {
        // Given
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.mockedLoadingState = false
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", useCase: useCase)
        XCTAssertFalse(viewModel.isLoggingIn)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
    }

    func test_errorMessage_is_correct_when_login_fails_with_incorrect_credentials() {
        // Given
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.mockedLoginError = .wrongCredentials
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", useCase: useCase)
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.wrongCredentials)
    }

    func test_errorMessage_is_correct_when_login_fails_with_generic_error() {
        // Given
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.mockedLoginError = .genericFailure(underlyingError: NSError(domain: "test", code: 500))
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com", useCase: useCase)
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.genericFailure)
    }

    func test_successHandler_is_triggered_when_login_succeeds() {
        // Given
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.shouldMockLoginSuccess = true
        var isLoginSuccess = false
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com",
                                                     useCase: useCase,
                                                     onLoginSuccess: { isLoginSuccess = true })
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertFalse(viewModel.shouldShowErrorAlert)
        XCTAssertTrue(isLoginSuccess)
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
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.mockedLoginError = .wrongCredentials
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics, useCase: useCase)

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_did_show_error_alert" }))
    }

    func test_it_tracks_login_jetpack_site_credential_did_finish_login_when_login_finishes() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let siteURL = "https://test.com"
        let useCase = MockSiteCredentialLoginUseCase()
        useCase.shouldMockLoginSuccess = true
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, analytics: analytics, useCase: useCase)

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
