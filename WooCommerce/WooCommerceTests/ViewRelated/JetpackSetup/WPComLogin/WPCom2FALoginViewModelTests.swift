import XCTest
@testable import WooCommerce
import class WordPressAuthenticator.LoginFields

final class WPCom2FALoginViewModelTests: XCTestCase {

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
        assertEqual("439992", "439992")
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
}
