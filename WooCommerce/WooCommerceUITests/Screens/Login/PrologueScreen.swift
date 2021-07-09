import ScreenObject
import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

final class PrologueScreen: ScreenObject {
    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.continueButton]
    }
    private let siteAddressButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.siteAddressButton]
    }

    private var continueButton: XCUIElement { expectedElement }
    private var siteAddressButton: XCUIElement { siteAddressButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: { $0.buttons[ElementStringIDs.continueButton] },
            app: app
        )
    }

    func selectContinueWithWordPress() -> GetStartedScreen {
        continueButton.tap()

        return GetStartedScreen()
    }

    func selectSiteAddress() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }
}
