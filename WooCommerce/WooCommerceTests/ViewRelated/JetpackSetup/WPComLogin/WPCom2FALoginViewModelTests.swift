import XCTest
@testable import WooCommerce
import WordPressAuthenticator

@MainActor
final class WPCom2FALoginViewModelTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
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
        viewModel.verificationCode = "1857878789"

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

    func test_isValidCode_when_verification_code_has_nine_digits_then_returns_true() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                            onAuthWindowRequest: { window },
                                            onLoginFailure: { _ in },
                                            onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = "012345678"

        // Then
        XCTAssertTrue(viewModel.isValidCode)
        XCTAssertEqual(viewModel.strippedCode, "012345678")
    }

    func test_isValidCode_when_nine_digit_code_contains_whitespace_then_returns_true() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewModel = WPCom2FALoginViewModel(loginFields: LoginFields(),
                                            onAuthWindowRequest: { window },
                                            onLoginFailure: { _ in },
                                            onLoginSuccess: { _ in })

        // When
        viewModel.verificationCode = " 012 345 678\n"

        // Then
        XCTAssertTrue(viewModel.isValidCode)
        XCTAssertEqual(viewModel.strippedCode, "012345678")
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

    func test_handleLogin_when_nonce_info_has_no_code_nonce_then_submits_code_with_password() {
        // Given
        let window = UIWindow(frame: UIScreen.main.bounds)
        let loginFields = LoginFields()
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        loginFields.nonceInfo = nonceInfo
        let loginFacade = MockLoginFacade(dotcomClientID: "Fake", dotcomSecret: "Fake", userAgent: "Fake")
        var failureWasCalled = false
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               loginFacade: loginFacade,
                                               onAuthWindowRequest: { window },
                                               onLoginFailure: { _ in failureWasCalled = true },
                                               onLoginSuccess: { _ in })
        viewModel.verificationCode = " 123 456 "

        // When
        viewModel.handleLogin()

        // Then
        XCTAssertTrue(viewModel.isLoggingIn)
        XCTAssertTrue(loginFacade.signedInLoginFields === loginFields)
        XCTAssertEqual(loginFacade.signedInLoginFields?.multifactorCode, "123456")
        XCTAssertEqual(loginFacade.signInCallCount, 1)
        XCTAssertEqual(loginFacade.nonceAuthenticationCallCount, 0)
        XCTAssertFalse(failureWasCalled)
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

    func test_security_key_mode_when_backup_is_available_then_switches_to_backup_code_instructions() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["webauthn", "backup"]
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        loginFields.nonceInfo = nonceInfo
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })
        XCTAssertTrue(viewModel.shouldShowBackupCodeOption)
        XCTAssertFalse(viewModel.shouldShowSecurityKeyOption)

        // When
        viewModel.useBackupCode()

        // Then
        XCTAssertFalse(viewModel.isSecurityKeyMode)
        XCTAssertFalse(viewModel.shouldShowBackupCodeOption)
        XCTAssertTrue(viewModel.shouldShowSecurityKeyOption)
        XCTAssertEqual(viewModel.instructions, "Enter a backup code to continue.")
    }

    func test_shouldShowOtherOptionsText_when_no_other_method_is_available_then_returns_false() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["authenticator"]

        // When
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowTextCodeOption)
        XCTAssertFalse(viewModel.shouldShowOtherOptionsText)
    }

    func test_use_backup_code_when_login_is_in_progress_then_keeps_security_key_mode() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["webauthn", "backup"]
        let loginFacade = MockLoginFacade(dotcomClientID: "Fake", dotcomSecret: "Fake", userAgent: "Fake")
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               loginFacade: loginFacade,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })
        viewModel.handleLogin()

        // When
        viewModel.useBackupCode()

        // Then
        XCTAssertTrue(viewModel.isLoggingIn)
        XCTAssertTrue(viewModel.isSecurityKeyMode)
        XCTAssertTrue(viewModel.shouldShowBackupCodeOption)
    }

    func test_request_one_time_code_when_sms_is_available_then_switches_to_text_message_instructions() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["authenticator", "sms"]
        let loginFacade = MockLoginFacade(dotcomClientID: "Fake", dotcomSecret: "Fake", userAgent: "Fake")
        let oauthFacade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        loginFacade.wordpressComOAuthClientFacade = oauthFacade
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               loginFacade: loginFacade,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })
        XCTAssertEqual(viewModel.textCodeButtonTitle(defaultTitle: "Text me a code"), "Text me a code")

        // When
        viewModel.requestOneTimeCode()

        // Then
        XCTAssertEqual(oauthFacade.oneTimeCodeRequestCount, 1)
        XCTAssertEqual(viewModel.instructions, "We sent a text message. Enter the verification code from the message.")
        XCTAssertEqual(viewModel.textCodeButtonTitle(defaultTitle: "Text me a code"), "Resend code via SMS")
    }

    func test_useBackupCode_when_code_entry_is_the_first_method_then_shows_backup_instructions_and_hides_backup_option() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["backup", "authenticator"]
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })
        XCTAssertTrue(viewModel.shouldShowBackupCodeOption)

        // When
        viewModel.useBackupCode()

        // Then
        XCTAssertEqual(viewModel.instructions, "Enter a backup code to continue.")
        XCTAssertFalse(viewModel.shouldShowBackupCodeOption)
        XCTAssertFalse(viewModel.shouldShowOtherOptionsText)
    }

    func test_requestOneTimeCode_when_backup_code_was_requested_then_shows_text_message_instructions_and_backup_option() {
        // Given
        let loginFields = LoginFields()
        loginFields.supportedAuthTypes = ["backup", "authenticator", "sms"]
        let loginFacade = MockLoginFacade(dotcomClientID: "Fake", dotcomSecret: "Fake", userAgent: "Fake")
        loginFacade.wordpressComOAuthClientFacade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        let viewModel = WPCom2FALoginViewModel(loginFields: loginFields,
                                               loginFacade: loginFacade,
                                               onAuthWindowRequest: { UIWindow(frame: UIScreen.main.bounds) },
                                               onLoginFailure: { _ in },
                                               onLoginSuccess: { _ in })
        viewModel.useBackupCode()

        // When
        viewModel.requestOneTimeCode()

        // Then
        XCTAssertEqual(viewModel.instructions, "We sent a text message. Enter the verification code from the message.")
        XCTAssertTrue(viewModel.shouldShowBackupCodeOption)
    }
}
