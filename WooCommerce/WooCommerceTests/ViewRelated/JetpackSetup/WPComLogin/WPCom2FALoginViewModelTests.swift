import XCTest
@testable import WooCommerce
import WordPressAuthenticator

final class WPCom2FALoginViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPCom2FALoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: true,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPCom2FALoginViewModel.Localization.connectJetpack, text)
    }

    func test_strippedCode_removes_all_white_spaces_from_verification_code() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "43 99 92"

        // Then
        assertEqual("439992", viewModel.strippedCode)
    }

    func test_isValidCode_returns_false_when_verification_code_contains_non_digits() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "43gd35"

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_false_when_verification_code_is_empty() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = ""

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_false_when_verification_code_is_too_long() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "185787878"

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_true_when_verification_has_acceptable_length() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "185787"

        //  Then
        XCTAssertTrue(viewModel.isValidCode)
    }

    func test_handleLogin_updates_loginFields_correctly() {
        // Given
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "113 567"
        viewModel.handleLogin()

        // Then
        assertEqual(viewModel.strippedCode, viewModel.loginFields.multifactorCode)
    }

    func test_isLoggingIn_is_updated_correctly_and_onLoginFailure_is_triggered_when_login_fails() {
        // Given
        var errorCaught: Error? = nil
        let expectedError = NSError(domain: "Test", code: 400)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
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
        var token: String? = nil
        let expectedToken = "secret"
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               requiresConnectionOnly: false,
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
