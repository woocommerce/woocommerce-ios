import XCTest

public final class TwoFAScreen {

    private let twoFAFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Authentication code"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    public let app: XCUIApplication

    private var twoFAField: XCUIElement { twoFAFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        self.app = app

        // iOS can show this prompt over 2FA after the password screen has already advanced.
        // Dismiss it before checking screen readiness.
        guard app.dismissSavePasswordPromptIfNeeded(timeout: 30) else {
            throw TwoFAScreenError.timedOut
        }

        // ScreenObject waits for the first element to be hittable. On iPad/iOS 26, visible 2FA
        // controls can stay non-hittable while the numeric keyboard is active, so wait by existence.
        guard twoFAField.waitForExistence(timeout: 30) else {
            throw TwoFAScreenError.timedOut
        }
    }

    @discardableResult
    public func enterValidTwoFACode() throws -> MyStoreScreen {
        try proceedWith(twoFACode: "123456")

        return try MyStoreScreen()
    }

    public func proceedWith(twoFACode: String) throws {
        enterTwoFACode(twoFACode)
        tapContinueButton()
    }

    private func enterTwoFACode(_ twoFACode: String) {
        app.dismissSavePasswordPromptIfNeeded(timeout: 2)
        XCTAssertTrue(twoFAField.waitForExistence(timeout: 10), "2FA field should be visible before typing.")

        focusTwoFAFieldIfNeeded()
        if tapTwoFACodeKeyboardKeys(twoFACode) {
            return
        }

        twoFAField.typeText(twoFACode)
    }

    private func focusTwoFAFieldIfNeeded() {
        if app.keyboards.firstMatch.exists {
            return
        }

        if twoFAField.isHittable {
            twoFAField.tap()
        } else if !twoFAField.frame.isEmpty {
            twoFAField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func tapTwoFACodeKeyboardKeys(_ twoFACode: String) -> Bool {
        guard app.keyboards.firstMatch.waitForExistence(timeout: 2) else {
            return false
        }

        let codeKeys = twoFACode.map { app.keyboards.keys[String($0)].firstMatch }
        guard codeKeys.allSatisfy({ $0.waitForIsHittable(timeout: 2) }) else {
            return false
        }

        codeKeys.forEach { $0.tap() }
        return true
    }

    private func tapContinueButton() {
        if continueButton.waitForIsHittable(timeout: 2) {
            continueButton.tap()
            return
        }

        dismissKeyboardIfNeeded()
        if continueButton.waitForIsHittable(timeout: 5) {
            continueButton.tap()
            return
        }

        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button should exist after entering the 2FA code.")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled after entering the 2FA code.")
        XCTAssertFalse(continueButton.frame.isEmpty, "Continue button should have a tappable frame after entering the 2FA code.")
        continueButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func dismissKeyboardIfNeeded() {
        guard app.keyboards.firstMatch.exists else {
            return
        }

        let keyboardDismissButtons = ["Done", "Hide keyboard"]
        for label in keyboardDismissButtons {
            let button = app.keyboards.buttons[label].firstMatch
            if button.exists && button.isHittable {
                button.tap()
                return
            }
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
    }

    private enum TwoFAScreenError: Error {
        case timedOut
    }
}
