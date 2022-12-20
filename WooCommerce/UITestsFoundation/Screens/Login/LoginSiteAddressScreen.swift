import ScreenObject
import XCTest

public final class LoginSiteAddressScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.buttons["Site Address Next Button"] },
                  { $0.textFields["Site address"] }
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    public func proceedWith(siteUrl: String) throws -> GetStartedScreen {
        app.textFields["Site address"].enterText(text: siteUrl)
        app.buttons["Site Address Next Button"].tap()
        return try GetStartedScreen()
    }
}
