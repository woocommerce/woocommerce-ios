import ScreenObject
import XCTest
import XCUITestHelpers

public final class LoginPasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.secureTextFields["Password"] },
                  { $0.buttons["Password Next Button"] },
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    func proceedWith(password: String) throws -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return try LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        XCTAssert(app.secureTextFields["Password"].waitForIsHittable(timeout: 3))
        app.secureTextFields["Password"].paste(text: password)

        XCTAssert(app.buttons["Password Next Button"].waitForIsHittable(timeout: 3))
        app.buttons["Password Next Button"].tap()

        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        let errorLabel = app.staticTexts["pswdErrorLabel"]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssert(errorLabel.waitForExistence(timeout: 3))
        return self
    }
}
