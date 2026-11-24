import XCTest

@MainActor
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

        let myStoreTitle = app.staticTexts["my-store-title"]
        guard app.dismissSavePasswordPromptIfNeeded(timeout: 30,
                                                    until: myStoreTitle,
                                                    elementDescription: "My Store title") else {
            throw TwoFAScreenError.timedOut
        }

        return try MyStoreScreen()
    }

    public func proceedWith(twoFACode: String) throws {
        try enterTwoFACode(twoFACode)
        try submitTwoFACode()
    }

    private func enterTwoFACode(_ twoFACode: String) throws {
        try dismissSavePasswordPrompt()
        XCTAssertTrue(twoFAField.waitForExistence(timeout: 10), "2FA field should be visible before typing.")

        focusTwoFAFieldIfNeeded()
        try enterTwoFACodeUsingFocusedField(twoFACode)
    }

    private func focusTwoFAFieldIfNeeded() {
        if twoFAField.isHittable {
            twoFAField.tap()
        } else if !twoFAField.frame.isEmpty {
            twoFAField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func enterTwoFACodeUsingFocusedField(_ twoFACode: String) throws {
        for (index, digit) in twoFACode.enumerated() {
            let expectedCode = String(twoFACode.prefix(index + 1))
            app.typeText(String(digit))
            guard waitForTwoFACode(expectedCode, timeout: Constants.digitEntryWaitTimeout) else {
                // A delayed system prompt can interrupt text entry after the 2FA screen appeared.
                try dismissSavePasswordPrompt()
                if waitForTwoFACode(expectedCode, timeout: Constants.promptRecoveryWaitTimeout) {
                    continue
                }
                focusTwoFAFieldIfNeeded()
                app.typeText(String(digit))
                guard waitForTwoFACode(expectedCode, timeout: Constants.digitEntryWaitTimeout) else {
                    XCTFail("2FA field should contain the complete authentication code after typing.")
                    return
                }
                continue
            }
        }
    }

    private func waitForTwoFACode(_ expectedCode: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if twoFAField.value as? String == expectedCode {
                return true
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return twoFAField.value as? String == expectedCode
    }

    private func dismissSavePasswordPrompt() throws {
        guard app.dismissSavePasswordPromptIfNeeded() else {
            throw TwoFAScreenError.timedOut
        }
    }

    private func submitTwoFACode() throws {
        try dismissSavePasswordPrompt()

        guard continueButton.waitForExistence(timeout: 5),
              continueButton.isEnabled,
              !continueButton.frame.isEmpty else {
            XCTFail("Continue button should be enabled and visible after entering the 2FA code.")
            throw TwoFAScreenError.timedOut
        }

        // Submit once. The code field can lose focus or disappear while the next screen loads.
        if continueButton.isHittable {
            continueButton.tap()
            return
        }

        // On iPad the numeric keyboard can make the on-screen Continue button non-hittable.
        let keyboardContinueButton = app.keyboards.buttons["Continue"].firstMatch
        if keyboardContinueButton.exists && keyboardContinueButton.isHittable {
            keyboardContinueButton.tap()
        } else if app.keyboards.firstMatch.exists {
            app.typeText("\n")
        } else {
            continueButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private enum TwoFAScreenError: Error {
        case timedOut
    }

    private enum Constants {
        static let digitEntryWaitTimeout: TimeInterval = 3
        static let promptRecoveryWaitTimeout: TimeInterval = 2
    }
}
