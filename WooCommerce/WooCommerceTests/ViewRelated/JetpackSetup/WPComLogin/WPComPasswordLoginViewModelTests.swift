import XCTest
@testable import WooCommerce
import WordPressAuthenticator

final class WPComPasswordLoginViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: "test@example.com",
                                                    requiresConnectionOnly: false,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComPasswordLoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: "test@example.com",
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComPasswordLoginViewModel.Localization.connectJetpack, text)
    }

    func test_gravatar_url_is_correct() throws {
        // Given
        let siteURL = "https://example.com"
        let email = "test@example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: email,
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let url = try XCTUnwrap(viewModel.avatarURL)

        // Then
        assertEqual("https://gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?d=mp&s=80&r=g", url.absoluteString)
    }

    func test_isLoggingIn_is_updated_correctly_and_onMultifactorCodeRequest_is_triggered_when_2FA_code_is_required() {
        // Given
        let siteURL = "https://example.com"
        let email = "test@example.com"
        let password = "secret"
        var loginFields: LoginFields? = nil

        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: email,
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { loginFields = $0 },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        viewModel.password = password
        viewModel.handleLogin()
        XCTAssertTrue(viewModel.isLoggingIn)
        viewModel.needsMultifactorCode()

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
        assertEqual(email, loginFields?.username)
        assertEqual(password, loginFields?.password)
        assertEqual(siteURL, loginFields?.siteAddress)
        assertEqual(true, loginFields?.meta.userIsDotCom)
    }

    func test_isLoggingIn_is_updated_correctly_and_onLoginFailure_is_triggered_when_login_fails() {
        // Given
        let siteURL = "https://example.com"
        let email = "test@example.com"
        var errorCaught: Error? = nil
        let expectedError = NSError(domain: "Test", code: 400)
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: email,
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { errorCaught = $0 },
                                                    onLoginSuccess: { _ in })

        // When
        viewModel.handleLogin()
        XCTAssertTrue(viewModel.isLoggingIn)
        viewModel.displayRemoteError(expectedError)

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
        assertEqual(expectedError, errorCaught as? NSError)
    }

    func test_isLoggingIn_is_updated_correctly_and_onLoginSuccess_is_triggered_when_login_succeeds() {
        // Given
        let siteURL = "https://example.com"
        let email = "test@example.com"
        var token: String? = nil
        let expectedToken = "secret"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: email,
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { token = $0 })
        // When
        viewModel.handleLogin()
        XCTAssertTrue(viewModel.isLoggingIn)
        viewModel.finishedLogin(withAuthToken: expectedToken, requiredMultifactorCode: false)

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
        assertEqual(token, expectedToken)
    }
}
