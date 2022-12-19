import ScreenObject
import XCTest

public final class PrologueScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: { Self.findContinueButton(in: $0) },
            app: app
        )
    }

    public func selectContinueWithWordPress() throws -> GetStartedScreen {
        Self.findContinueButton(in: app).tap()
        return try GetStartedScreen()
    }

    public func selectSiteAddress() throws -> LoginSiteAddressScreen {
        app.buttons["Prologue Self Hosted Button"].tap()

        return try LoginSiteAddressScreen()
    }

    @discardableResult
    public func verifyPrologueScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}

extension PrologueScreen {
    static func findContinueButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons["Prologue Continue Button"]
    }

    public static func isSiteAddressLoginAvailable(in app: XCUIApplication = .init()) -> Bool {
        app.buttons["Prologue Self Hosted Button"].waitForExistence(timeout: 1)
    }
}
