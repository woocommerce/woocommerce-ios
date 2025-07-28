import ScreenObject
import XCTest

public final class PrologueScreen: ScreenObject {

    private let titleLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["prologue-title-label"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Continue Button"]
    }

    private let logInButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Self Hosted Button"]
    }

    private var continueButton: XCUIElement { continueButtonGetter(app) }
    private var logInButton: XCUIElement { logInButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                /// due to the changes of CTAs on the prologue screen,
                /// it is safer to check for the title label only.
                titleLabelGetter
            ],
            app: app
        )
    }

    public func tapContinueWithWordPress() throws -> GetStartedScreen {
        continueButton.tap()
        return try GetStartedScreen()
    }

    public func tapLogIn() throws -> LoginSiteAddressScreen {
        logInButton.tap()
        return try LoginSiteAddressScreen()
    }

    @discardableResult
    public func verifyPrologueScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    public func isSiteAddressLoginAvailable() throws -> Bool {
        logInButton.waitForExistence(timeout: 1)
    }

    public func isWPComLoginAvailable() throws -> Bool {
        continueButton.waitForExistence(timeout: 1)
    }
}
