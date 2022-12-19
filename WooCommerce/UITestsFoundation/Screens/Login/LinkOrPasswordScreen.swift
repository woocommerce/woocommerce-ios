import ScreenObject
import XCTest

public final class LinkOrPasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.buttons["Use Password"] },
                  { $0.buttons["Send Link Button"] },
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        app.buttons["Use Password"].tap()

        return try LoginPasswordScreen()
    }

    func proceedWithLink() throws -> LoginCheckMagicLinkScreen {
        app.buttons["Send Link Button"].tap()

        return try LoginCheckMagicLinkScreen()
    }

    func isLoaded() -> Bool {
        return app.buttons["Use Password"].exists
    }
}
