import XCTest
@testable import WooCommerce
import WordPressAuthenticator

final class WPCom2FALoginViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    func test_strippedCode_removes_all_white_spaces_from_verification_code() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "43 99 92"

        // Then
        assertEqual("439992", viewModel.strippedCode)
    }

    func test_isValidCode_returns_false_when_verification_code_contains_non_digits() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "43gd35"

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_false_when_verification_code_is_empty() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = ""

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_false_when_verification_code_is_too_long() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "185787878"

        //  Then
        XCTAssertFalse(viewModel.isValidCode)
    }

    func test_isValidCode_returns_true_when_verification_has_acceptable_length() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "185787"

        //  Then
        XCTAssertTrue(viewModel.isValidCode)
    }

    func test_isLoggingIn_is_updated_correctly_and_onLoginFailure_is_triggered_when_login_fails() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        var errorCaught: TwoFALoginError? = nil
        let expectedError = NSError(domain: "Test", code: 400)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { errorCaught = $0 },
                                               onLoginSuccess: { _ in })

        // When
        viewModel.handleLogin()
        XCTAssertTrue(viewModel.isLoggingIn)
        viewModel.displayRemoteError(expectedError)

        // Then
        XCTAssertFalse(viewModel.isLoggingIn)
        XCTAssertEqual(errorCaught, .genericFailure(underlyingError: expectedError))
    }

    func test_isLoggingIn_is_updated_correctly_and_onLoginSuccess_is_triggered_when_login_succeeds() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        var token: String? = nil
        let expectedToken = "secret"
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { token = $0 })
        // When
        viewModel.handleLogin()
        XCTAssertTrue(viewModel.isLoggingIn)
        viewModel.finishedLogin(withAuthToken: expectedToken, requiredMultifactorCode: false)

        // Then
        waitUntil {
            viewModel.isLoggingIn == false
        }
        assertEqual(token, expectedToken)
    }

    func test_shouldEnableSecurityKeyOption_returns_false_if_nonce_info_is_not_present() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let loginFields = LoginFields()
        loginFields.nonceInfo = nil

        // When
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // Then
        XCTAssertFalse(viewModel.shouldEnableSecurityKeyOption)
    }

    func test_shouldEnableSecurityKeyOption_returns_true_if_nonce_info_is_present() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let loginFields = LoginFields()
        loginFields.nonceInfo = .init()

        // When
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // Then
        XCTAssertTrue(viewModel.shouldEnableSecurityKeyOption)
    }
}
