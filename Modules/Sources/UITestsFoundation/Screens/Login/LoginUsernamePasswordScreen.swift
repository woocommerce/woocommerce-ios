import ScreenObject
import XCTest

public final class LoginUsernamePasswordScreen: ScreenObject {

    private let submitButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["submitButton"]
    }

    private let usernameFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["usernameField"]
    }

    private let passwordFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["passwordField"]
    }

    private var submitButton: XCUIElement { submitButtonGetter(app) }
    private var usernameField: XCUIElement { usernameFieldGetter(app) }
    private var passwordField: XCUIElement { passwordFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                submitButtonGetter,
                usernameFieldGetter,
                passwordFieldGetter
            ],
            app: app
        )
    }

    func proceedWith(username: String, password: String) throws -> LoginEpilogueScreen {
        usernameField.enterText(text: username)
        passwordField.enterText(text: password)
        submitButton.tap()

        return try LoginEpilogueScreen()
    }
}
