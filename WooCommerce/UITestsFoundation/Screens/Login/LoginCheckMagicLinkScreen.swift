import ScreenObject
import XCTest

public final class LoginCheckMagicLinkScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.buttons["Use Password"] },
                  { $0.buttons["Open Mail Button"] },
                  { $0.alerts.element(boundBy: 0) }
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        app.buttons["Use Password"].tap()

        return try LoginPasswordScreen()
    }
}
