import ScreenObject
import XCTest

public final class LoginEpilogueScreen: ScreenObject {

    private let emailLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["email-label"]
    }

    private let urlLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["url-label"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["login-epilogue-continue-button"]
    }

    private var emailLabel: String { emailLabelGetter(app).label }
    private var siteUrlLabel: String { urlLabelGetter(app).label }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                emailLabelGetter,
                urlLabelGetter,
                continueButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func continueWithSelectedSite() throws -> MyStoreScreen {
        continueButton.tap()
        return try MyStoreScreen()
    }

    public func verifyEpilogueDisplays(email expectedEmail: String, siteUrl expectedSiteUrl: String) -> LoginEpilogueScreen {
        XCTAssertEqual(expectedEmail, emailLabel, "Display name is '\(emailLabel)' but should be '\(expectedEmail)'.")
        XCTAssertEqual(expectedSiteUrl, siteUrlLabel, "Site URL is \(siteUrlLabel) but should be \(expectedSiteUrl)")

        return self
    }
}
