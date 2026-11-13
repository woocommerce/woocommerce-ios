import ScreenObject
import XCTest

@MainActor
public final class LoginSiteAddressScreen: ScreenObject {

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Site Address Next Button"]
    }

    private let siteAddressFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Site address"]
    }

    private let helpButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["authenticator-help-button"]
    }

    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var siteAddressField: XCUIElement { siteAddressFieldGetter(app) }
    private var helpButton: XCUIElement { helpButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                siteAddressFieldGetter,
                nextButtonGetter
            ],
            app: app
        )
    }

    public func proceedWith(siteUrl: String) throws -> GetStartedScreen {
        siteAddressField.enterText(text: siteUrl)
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), "Site address Next button should exist after entering the site URL.")
        XCTAssertTrue(nextButton.waitForIsHittable(timeout: 10), "Site address Next button should be tappable after entering the site URL.")
        nextButton.tap()

        return try GetStartedScreen()
    }

    public func tapHelpButton() throws -> HelpScreen {
        helpButton.tap()

        return try HelpScreen()
    }
}
