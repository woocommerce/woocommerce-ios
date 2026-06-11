import ScreenObject
import XCTest

public final class TwoFAScreen: ScreenObject {

    private let twoFAFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Authentication code"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    private var twoFAField: XCUIElement { twoFAFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // iOS can show this prompt over 2FA after the password screen has already advanced.
        // Dismiss it before ScreenObject waits for the covered 2FA field to become hittable.
        guard app.dismissSavePasswordPromptIfNeeded(
            timeout: 30,
            until: app.textFields["Authentication code"],
            stableFor: 0.5,
            elementDescription: "2FA field"
        ) else {
            throw ScreenObject.WaitForScreenError.timedOut
        }
        try super.init(
            expectedElementGetters: [
                twoFAFieldGetter,
                continueButtonGetter
            ],
            app: app,
            waitTimeout: 2
        )
    }

    @discardableResult
    public func enterValidTwoFACode() throws -> MyStoreScreen {
        try proceedWith(twoFACode: "123456")

        return try MyStoreScreen()
    }

    public func proceedWith(twoFACode: String) throws {
        enterTwoFACode(twoFACode)
        XCTAssertTrue(continueButton.waitForIsHittable(timeout: 10), "Continue button should be tappable after entering the 2FA code.")
        continueButton.tap()
    }

    private func enterTwoFACode(_ twoFACode: String) {
        app.dismissSavePasswordPromptIfNeeded(timeout: 2)
        XCTAssertTrue(twoFAField.waitForIsHittable(timeout: 10), "2FA field should be ready for typing.")

        twoFAField.tap()
        if tapTwoFACodeKeyboardKeys(twoFACode) {
            return
        }

        twoFAField.typeText(twoFACode)
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
}
