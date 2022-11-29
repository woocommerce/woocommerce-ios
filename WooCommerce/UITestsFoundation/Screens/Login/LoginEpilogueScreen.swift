import XCTest

private struct ElementStringIDs {
    static let emailField = "email-label"
    static let siteUrlField = "url-label"
    static let continueButton = "login-epilogue-continue-button"
}

public final class LoginEpilogueScreen: BaseScreen {
    private let continueButton: XCUIElement
    private let emailField: XCUIElement
    private let siteUrlField: XCUIElement

    public init() {
        let app = XCUIApplication()
        emailField = app.staticTexts[ElementStringIDs.emailField]
        siteUrlField = app.staticTexts[ElementStringIDs.siteUrlField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: continueButton)
    }

    @discardableResult
    public func continueWithSelectedSite() throws -> MyStoreScreen {
        continueButton.tap()
        return try MyStoreScreen()
    }

    public func verifyEpilogueDisplays(email expectedEmail: String, siteUrl expectedSiteUrl: String) -> LoginEpilogueScreen {
        let actualEmail = emailField.label
        let actualSiteUrl = siteUrlField.label

        XCTAssertEqual(expectedEmail, actualEmail, "Display name is '\(actualEmail)' but should be '\(expectedEmail)'.")
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl, "Site URL is \(actualSiteUrl) but should be \(expectedSiteUrl)")

        return self
    }
}
