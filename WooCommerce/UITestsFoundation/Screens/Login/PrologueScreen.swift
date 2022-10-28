import ScreenObject
import XCTest

public final class PrologueScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: { Self.findContinueButton(in: $0) },
            app: app
        )
    }

    public func selectContinueWithWordPress() -> GetStartedScreen {
        Self.findContinueButton(in: app).tap()
        return GetStartedScreen()
    }

    public func selectSiteAddress() -> LoginSiteAddressScreen {
        app.buttons["Prologue Self Hosted Button"].tap()

        return LoginSiteAddressScreen()
    }

    @discardableResult
    public func verifyPrologueScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}

extension PrologueScreen {
    static func findContinueButton(in app: XCUIApplication) -> XCUIElement {
        let continueButton = app.buttons["Prologue Continue Button"]
        if continueButton.waitForExistence(timeout: 1) {
            return continueButton
        } else {
            // On simplified login flow, the button has different identifier
            return app.buttons["Prologue Log In Button"]
        }
    }

    public static func isSiteAddressLoginAvailable(in app: XCUIApplication = .init()) -> Bool {
        app.buttons["Prologue Self Hosted Button"].waitForExistence(timeout: 1)
    }
}
