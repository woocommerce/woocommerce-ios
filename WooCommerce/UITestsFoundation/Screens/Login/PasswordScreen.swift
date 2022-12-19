import ScreenObject
import XCTest

public final class PasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.secureTextFields["Password"] },
                  { $0.buttons["Continue Button"] },
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    public func proceedWith(password: String) throws {
        _ = try tryProceed(password: password)
    }

    public func tryProceed(password: String) throws -> PasswordScreen {
        let continueButton = app.buttons["Continue Button"]
        
        app.secureTextFields["Password"].enterText(text: password)
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }
        return self
    }

    public func verifyLoginError() throws -> PasswordScreen {
        let errorLabel = app.cells["Password Error"]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    func isLoaded() -> Bool {
        return app.buttons["Continue Button"].exists
    }
}
