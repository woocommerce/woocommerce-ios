import Foundation
import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

final class PrologueScreen: BaseScreen {
    private let continueButton: XCUIElement
    private let siteAddressButton: XCUIElement

    init() {
        continueButton = XCUIApplication().buttons[ElementStringIDs.continueButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        super.init(element: continueButton)
    }

    func selectContinueWithWordPress() -> GetStartedScreen {
        continueButton.tap()

        return GetStartedScreen()
    }

    func selectSiteAddress() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
