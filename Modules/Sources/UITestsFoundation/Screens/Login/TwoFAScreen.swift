import XCTest

public final class TwoFAScreen {

    private let twoFAFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Authentication code"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    private let myStoreTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-my-store-item"]
    }

    public let app: XCUIApplication

    private var twoFAField: XCUIElement { twoFAFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }
    private var myStoreTab: XCUIElement { myStoreTabGetter(app) }

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
        submitTwoFACode()
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

    private func submitTwoFACode() {
        if hasAdvancedPastTwoFA() {
            return
        }

        // On iPad/iOS 26 the numeric keypad can keep the on-screen CTA non-hittable,
        // while submitting from the focused field advances reliably.
        if submitFromFocusedFieldIfPossible() {
            return
        }

        XCTAssertTrue(waitForContinueButtonReady(timeout: 5), "Continue button should be enabled after entering the 2FA code.")
        tapContinueButton()
    }

    private func waitForContinueButtonReady(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if hasAdvancedPastTwoFA() {
                return true
            }

            if continueButton.exists && continueButton.isEnabled && !continueButton.frame.isEmpty {
                return true
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        if hasAdvancedPastTwoFA() {
            return true
        }

        return continueButton.exists && continueButton.isEnabled && !continueButton.frame.isEmpty
    }

    private func submitFromFocusedFieldIfPossible() -> Bool {
        guard app.keyboards.firstMatch.exists else {
            return false
        }

        let keyboardContinueButton = app.keyboards.buttons["Continue"].firstMatch
        if keyboardContinueButton.exists && keyboardContinueButton.isHittable {
            keyboardContinueButton.tap()
            if waitForSubmissionToStart(timeout: 1) {
                return true
            }
        }

        app.typeText("\n")
        if waitForSubmissionToStart(timeout: 1) {
            return true
        }

        if hasAdvancedPastTwoFA() {
            return true
        }

        guard twoFAField.exists else {
            return hasAdvancedPastTwoFA()
        }

        twoFAField.typeText("\n")
        return waitForSubmissionToStart(timeout: 1)
    }

    private func waitForSubmissionToStart(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if hasAdvancedPastTwoFA() || !twoFAField.exists {
                return true
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        return hasAdvancedPastTwoFA() || !twoFAField.exists
    }

    private func hasAdvancedPastTwoFA() -> Bool {
        myStoreTab.exists || app.staticTexts["Your WooCommerce Store"].exists
    }

    private func tapContinueButton() {
        if hasAdvancedPastTwoFA() {
            return
        }

        if tapContinueButtonIfReady() {
            return
        }

        dismissKeyboardIfNeeded()
        if hasAdvancedPastTwoFA() {
            return
        }

        if tapContinueButtonIfReady() {
            return
        }

        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button should exist after entering the 2FA code.")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled after entering the 2FA code.")
        XCTAssertFalse(continueButton.frame.isEmpty, "Continue button should have a tappable frame after entering the 2FA code.")
        XCTFail("2FA submission should start after tapping Continue.")
    }

    private func tapContinueButtonIfReady() -> Bool {
        if hasAdvancedPastTwoFA() {
            return true
        }

        guard continueButton.exists && continueButton.isEnabled && !continueButton.frame.isEmpty else {
            return false
        }

        if continueButton.isHittable {
            continueButton.tap()
        } else {
            continueButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        return waitForSubmissionToStart(timeout: 3)
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
                waitForKeyboardToDismiss(timeout: 1)
                if !app.keyboards.firstMatch.exists {
                    return
                }
            }
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        waitForKeyboardToDismiss(timeout: 1)
    }

    private func waitForKeyboardToDismiss(timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if !app.keyboards.firstMatch.exists {
                return
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    private enum TwoFAScreenError: Error {
        case timedOut
    }
}
