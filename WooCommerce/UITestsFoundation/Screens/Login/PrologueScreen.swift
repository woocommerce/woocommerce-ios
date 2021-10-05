import ScreenObject
import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

public final class PrologueScreen: ScreenObject {

    private var continueButton: XCUIElement { expectedElement }
    private var siteAddressButton: XCUIElement { app.buttons[ElementStringIDs.siteAddressButton] }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: { $0.buttons[ElementStringIDs.continueButton] },
            app: app
        )
    }

    public func selectContinueWithWordPress() -> GetStartedScreen {
        continueButton.tap()

        return GetStartedScreen()
    }

    public func selectSiteAddress() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }
}
