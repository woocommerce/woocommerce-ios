import XCTest

private struct ElementStringIDs {
    static let displayNameField = "full-name-label"
    static let siteUrlField = "url-label"
    static let continueButton = "login-epilogue-continue-button"
}

public final class LoginEpilogueScreen: BaseScreen {
    private let continueButton: XCUIElement
    private let displayNameField: XCUIElement
    private let siteUrlField: XCUIElement

    init() {
        let app = XCUIApplication()
        displayNameField = app.staticTexts[ElementStringIDs.displayNameField]
        siteUrlField = app.staticTexts[ElementStringIDs.siteUrlField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: continueButton)
    }

    public func continueWithSelectedSite() throws -> MyStoreScreen {
        continueButton.tap()
        return try MyStoreScreen()
    }

    public func verifyEpilogueDisplays(displayName expectedDisplayName: String, siteUrl expectedSiteUrl: String) -> LoginEpilogueScreen {
        let actualDisplayName = displayNameField.label
        let actualSiteUrl = siteUrlField.label

        XCTAssertEqual(expectedDisplayName, actualDisplayName, "Display name is '\(actualDisplayName)' but should be '\(expectedDisplayName)'.")
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl, "Site URL is \(actualSiteUrl) but should be \(expectedSiteUrl)")

        return self
    }
}
