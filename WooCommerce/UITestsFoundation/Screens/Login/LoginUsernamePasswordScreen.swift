import ScreenObject
import XCTest

public final class LoginUsernamePasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.buttons["submitButton"] },
                  { $0.textFields["usernameField"] },
                  { $0.textFields["passwordField"] }
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    func proceedWith(username: String, password: String) throws -> LoginEpilogueScreen {
        app.textFields["usernameField"].enterText(text: username)
        app.textFields["passwordField"].enterText(text: password)
        app.buttons["submitButton"].tap()

        return try LoginEpilogueScreen()
    }

    func isLoaded() -> Bool {
        return app.buttons["submitButton"].exists
    }
}
