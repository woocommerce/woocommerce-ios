import Testing
import UIKit
@testable import WordPressAuthenticator

@MainActor
struct TwoFactorCodeValidationTests {
    enum Screen: CaseIterable {
        case unified
        case legacy
    }

    @Test(arguments: Screen.allCases)
    func test_typing_when_code_has_nine_digits_then_accepts_code_and_enables_submit(screen: Screen) throws {
        // Given
        let (controller, textField) = try makeScreen(screen)
        let code = "012345678"

        // When
        for digit in code {
            let range = NSRange(location: (textField.text ?? "").utf16.count, length: 0)
            _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: String(digit))
        }

        // Then
        #expect(textField.text == code)
        #expect(controller.loginFields.multifactorCode == code)
        #expect(controller.submitButton?.isEnabled == true)
    }

    @Test(arguments: Screen.allCases, ["123456", "1234567", "12345678", "012345678", " 012 345 678\n"])
    func test_pasting_when_code_has_supported_length_then_accepts_code_and_enables_submit(screen: Screen, code: String) throws {
        // Given
        let (controller, textField) = try makeScreen(screen)

        // When
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: code)

        // Then
        let expectedCode = code.components(separatedBy: .whitespacesAndNewlines).joined()
        #expect(textField.text == expectedCode)
        #expect(controller.loginFields.multifactorCode == expectedCode)
        #expect(controller.submitButton?.isEnabled == true)
    }

    @Test(arguments: Screen.allCases, ["0", "a"])
    func test_typing_when_code_already_has_nine_digits_then_rejects_additional_characters(screen: Screen, character: String) throws {
        // Given
        let (controller, textField) = try makeScreen(screen)
        let code = "012345678"
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: code)

        // When
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 9, length: 0), replacementString: character)

        // Then
        #expect(textField.text == code)
        #expect(controller.loginFields.multifactorCode == code)
        #expect(controller.submitButton?.isEnabled == true)
    }

    @Test(arguments: Screen.allCases, ["0123456789", "01234a678"])
    func test_pasting_when_code_is_invalid_then_rejects_code(screen: Screen, code: String) throws {
        // Given
        let (controller, textField) = try makeScreen(screen)

        // When
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: code)

        // Then
        #expect(textField.text?.isEmpty == true)
        #expect(controller.loginFields.multifactorCode.isEmpty)
        #expect(controller.submitButton?.isEnabled == false)
    }

    @Test(arguments: Screen.allCases)
    func test_deleting_when_code_has_nine_digits_then_allows_editing_and_clearing(screen: Screen) throws {
        // Given
        let (controller, textField) = try makeScreen(screen)
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "012345678")

        // When
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 8, length: 1), replacementString: "")

        // Then
        #expect(textField.text == "01234567")
        #expect(controller.loginFields.multifactorCode == "01234567")
        #expect(controller.submitButton?.isEnabled == true)

        // When
        _ = textField.delegate?.textField?(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 8), replacementString: "")

        // Then
        #expect(textField.text?.isEmpty == true)
        #expect(controller.loginFields.multifactorCode.isEmpty)
        #expect(controller.submitButton?.isEnabled == false)
    }

    @Test(arguments: Screen.allCases, ["", "12345", "0123456789", "01234a678"])
    func test_submit_when_code_is_invalid_then_disables_button(screen: Screen, code: String) throws {
        // Given
        let (controller, _) = try makeScreen(screen)
        controller.loginFields.multifactorCode = code

        // When
        controller.configureSubmitButton(animating: false)

        // Then
        #expect(controller.submitButton?.isEnabled == false)
    }

    @Test(arguments: Screen.allCases)
    func test_submit_when_loading_with_nine_digit_code_then_disables_button(screen: Screen) throws {
        // Given
        let (controller, _) = try makeScreen(screen)
        controller.loginFields.multifactorCode = "012345678"

        // When
        controller.configureSubmitButton(animating: true)

        // Then
        #expect(controller.submitButton?.isEnabled == false)
    }

    private func makeScreen(_ screen: Screen) throws -> (LoginViewController, UITextField) {
        WordPressAuthenticator.initializeForTesting()

        switch screen {
        case .unified:
            let controller = try #require(TwoFAViewController.instantiate(from: .twoFA))
            controller.loadViewIfNeeded()
            controller.configureSubmitButton(animating: false)
            let tableView: UITableView = try #require(firstSubview(in: controller.view))
            let cells = (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
                controller.tableView(tableView, cellForRowAt: IndexPath(row: $0, section: 0))
            }
            let cell = try #require(cells.compactMap { $0 as? TextFieldTableViewCell }.first)
            return (controller, cell.textField)
        case .legacy:
            let controller = try #require(Login2FAViewController.instantiate(from: .login))
            controller.loadViewIfNeeded()
            return (controller, try #require(controller.verificationCodeField))
        }
    }

    private func firstSubview<View: UIView>(in view: UIView) -> View? {
        if let match = view as? View {
            return match
        }
        return view.subviews.lazy.compactMap { firstSubview(in: $0) as View? }.first
    }
}
