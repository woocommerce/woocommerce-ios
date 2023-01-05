import ScreenObject
import XCTest

public final class LoginSiteAddressScreen: ScreenObject {

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Site Address Next Button"]
    }

    private let siteAddressFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Site address"]
    }

    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var siteAddressField: XCUIElement { siteAddressFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                nextButtonGetter,
                siteAddressFieldGetter
            ],
            app: app
        )
    }

    public func proceedWith(siteUrl: String) throws -> GetStartedScreen {
        siteAddressField.enterText(text: siteUrl)
        nextButton.tap()

        return try GetStartedScreen()
    }
}
