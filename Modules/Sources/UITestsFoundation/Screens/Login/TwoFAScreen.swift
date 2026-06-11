import ScreenObject
import XCTest

public final class TwoFAScreen: ScreenObject {

    private let twoFAFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Authentication code"]
    }

    private let securityKeyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Passkeys"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    private var twoFAField: XCUIElement { twoFAFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                securityKeyButtonGetter, // Please keep this element at the beginning of this list to ensure its presence via the internal waitForScreen
                twoFAFieldGetter,
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
        enterTwoFACode(twoFACode)
        XCTAssertTrue(continueButton.waitForIsHittable(timeout: 10), "Continue button should be tappable after entering the 2FA code.")
        continueButton.tap()
    }

    private func enterTwoFACode(_ twoFACode: String) {
        app.dismissSavePasswordPromptIfNeeded(timeout: 2, until: twoFAField, stableFor: 0.5)
        XCTAssertTrue(twoFAField.waitForIsHittable(timeout: 10), "2FA field should be ready for typing.")

        twoFAField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.dismissSavePasswordPromptIfNeeded(timeout: 2, until: twoFAField, stableFor: 0.5)
        twoFAField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        twoFAField.typeText(twoFACode)
    }
}
