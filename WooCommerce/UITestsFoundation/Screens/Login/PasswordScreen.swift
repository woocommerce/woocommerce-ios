import ScreenObject
import XCTest

public final class PasswordScreen: ScreenObject {

    private let passwordFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    private let passwordErrorLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Password Error"]
    }

    private var passwordField: XCUIElement { passwordFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }
    private var passwordErrorLabel: XCUIElement { passwordErrorLabelGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordFieldGetter,
                continueButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func enterValidPassword() throws -> TwoFAScreen {
        try proceedWith(password: "pw")

        return try TwoFAScreen()
    }

    public func enterInvalidPassword() throws -> PasswordScreen {
        try proceedWith(password: "invalidPswd")
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }

        return try PasswordScreen()
    }

    public func proceedWith(password: String) throws {
        passwordField.enterText(text: password)
        continueButton.tap()

        // As of Xcode 14.3, the Simulator might ask to save the password which, of course, we don't want to do.
        if app.buttons["Save Password"].waitForExistence(timeout: 15) {
            // There should be no need to wait for this button to exist since it's part of the same
            // alert where "Save Password" is.
            let dismissButton = app.buttons["Not Now"]
            // Additionally wait for existence of the button to account for animations, even though the test runner should wait for the app
            // to idle before moving on.
            XCTAssertTrue(dismissButton.waitForExistence(timeout: 2))
            dismissButton.tap()
        }
    }

    @discardableResult
    public func verifyLoginError() throws -> PasswordScreen {
        _ = passwordErrorLabel.waitForExistence(timeout: 2)
        XCTAssertTrue(passwordErrorLabel.exists)

        return self
    }
}
