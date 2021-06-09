import ScreenObject
import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

final class PrologueScreen: ScreenObject {
    private let continueButton: XCUIElement
    private let siteAddressButton: XCUIElement

    init(app: XCUIApplication = XCUIApplication()) throws {
        continueButton = XCUIApplication().buttons[ElementStringIDs.continueButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        try super.init(
            probeElementGetter: { $0.buttons[ElementStringIDs.continueButton] },
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
