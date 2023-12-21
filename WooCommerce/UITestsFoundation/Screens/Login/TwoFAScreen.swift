import ScreenObject
import XCTest

public final class TwoFAScreen: ScreenObject {

    private let two2FAFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Authentication code"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    private var twoFAField: XCUIElement { two2FAFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                two2FAFieldGetter,
                continueButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func enterValidTwoFACode() throws -> MyStoreScreen {
        try proceedWith(twoFACode: "123456")

        return try MyStoreScreen()
    }

    public func proceedWith(twoFACode: String) throws {
        twoFAField.enterText(text: twoFACode)
        continueButton.tap()
    }
}
