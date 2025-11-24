import ScreenObject
import XCTest
import XCUITestHelpers

public final class LoginPasswordScreen: ScreenObject {

    private let passwordFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Password Next Button"]
    }

    private let passwordErrorLabel: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["pswdErrorLabel"]
    }

    private var passwordField: XCUIElement { passwordFieldGetter(app) }
    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var errorLabel: XCUIElement {passwordErrorLabel(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordFieldGetter,
                nextButtonGetter
            ],
            app: app
        )
    }

    func proceedWith(password: String) throws -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return try LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        XCTAssert(passwordField.waitForIsHittable(timeout: 3))
        passwordField.paste(text: password)

        XCTAssert(nextButton.waitForIsHittable(timeout: 3))
        nextButton.tap()

        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        XCTAssert(errorLabel.waitForExistence(timeout: 3))
        return self
    }
}
