import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.PasswordView"
    static let passwordTextField = "Password"
    static let continueButton = "Continue Button"
    static let errorLabel = "Password Error"
}

public final class PasswordScreen: BaseScreen {
    private let navBar: XCUIElement
    private let passwordTextField: XCUIElement
    private let continueButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        passwordTextField = app.secureTextFields[ElementStringIDs.passwordTextField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: passwordTextField)
    }

    public func proceedWith(password: String) {
        _ = tryProceed(password: password)
    }

    public func tryProceed(password: String) -> PasswordScreen {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }
        return self
    }

    public func verifyLoginError() -> PasswordScreen {
        let errorLabel = app.cells[ElementStringIDs.errorLabel]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
