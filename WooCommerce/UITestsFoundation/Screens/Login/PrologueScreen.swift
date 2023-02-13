import ScreenObject
import XCTest

public final class PrologueScreen: ScreenObject {

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Continue Button"]
    }

    private let selectSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Self Hosted Button"]
    }

    private var continueButton: XCUIElement { continueButtonGetter(app) }
    private var selectSiteButton: XCUIElement { selectSiteButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                continueButtonGetter,
                selectSiteButtonGetter
            ],
            app: app
        )
    }

    public func selectContinueWithWordPress() throws -> GetStartedScreen {
        continueButton.tap()
        return try GetStartedScreen()
    }

    public func selectSiteAddress() throws -> LoginSiteAddressScreen {
        selectSiteButton.tap()
        return try LoginSiteAddressScreen()
    }

    @discardableResult
    public func verifyPrologueScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    public func isSiteAddressLoginAvailable() throws -> Bool {
        selectSiteButton.waitForExistence(timeout: 1)
    }

    public func isWPComLoginAvailable() throws -> Bool {
        continueButton.waitForExistence(timeout: 1)
    }
}
