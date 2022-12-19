import ScreenObject
import XCTest

public final class GetStartedScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.textFields["Email address"] },
                  { $0.buttons["Get Started Email Continue Button"] },
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    public func proceedWith(email: String) throws -> PasswordScreen {
        app.textFields["Email address"].enterText(text: email)
        app.buttons["Get Started Email Continue Button"].tap()

        return try PasswordScreen()
    }

    func isLoaded() -> Bool {
        return app.buttons["Get Started Email Continue Button"].exists
    }

    func isEmailEntered() -> Bool {
        return app.textFields["Email address"].value != nil
    }
}
