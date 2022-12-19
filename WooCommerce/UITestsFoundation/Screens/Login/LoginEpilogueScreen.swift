import ScreenObject
import XCTest

public final class LoginEpilogueScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.staticTexts["email-label"] },
                  { $0.staticTexts["url-label"] },
                  { $0.buttons["login-epilogue-continue-button"] },
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    @discardableResult
    public func continueWithSelectedSite() throws -> MyStoreScreen {
        app.buttons["login-epilogue-continue-button"].tap()
        return try MyStoreScreen()
    }

    public func verifyEpilogueDisplays(email expectedEmail: String, siteUrl expectedSiteUrl: String) -> LoginEpilogueScreen {
        let actualEmail = app.staticTexts["email-label"].label
        let actualSiteUrl = app.staticTexts["url-label"].label

        XCTAssertEqual(expectedEmail, actualEmail, "Display name is '\(actualEmail)' but should be '\(expectedEmail)'.")
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl, "Site URL is \(actualSiteUrl) but should be \(expectedSiteUrl)")

        return self
    }
}
