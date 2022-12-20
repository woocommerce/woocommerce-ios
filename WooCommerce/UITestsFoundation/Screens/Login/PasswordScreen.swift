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

    public func proceedWith(password: String) throws {
        _ = try tryProceed(password: password)
    }

    public func tryProceed(password: String) throws -> PasswordScreen {
        passwordField.enterText(text: password)
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }

        return self
    }

    public func verifyLoginError() throws -> PasswordScreen {
        _ = passwordErrorLabel.waitForExistence(timeout: 2)
        XCTAssertTrue(passwordErrorLabel.exists)

        return self
    }
}
