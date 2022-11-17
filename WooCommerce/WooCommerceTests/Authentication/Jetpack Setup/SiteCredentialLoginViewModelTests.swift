import XCTest
@testable import WooCommerce
import WordPressAuthenticator

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
        viewModel.displayRemoteError(NSError(domain: "Test", code: 3))

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, SiteCredentialLoginViewModel.Localization.wrongCredentials)
    }
}
