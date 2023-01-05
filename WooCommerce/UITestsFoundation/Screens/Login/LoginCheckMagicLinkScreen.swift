import ScreenObject
import XCTest

public final class LoginCheckMagicLinkScreen: ScreenObject {

    private let passwordButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }

    private let mailAlertGetter: (XCUIApplication) -> XCUIElement = {
        $0.alerts.element(boundBy: 0)
    }

    private var passwordButton: XCUIElement { passwordButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordButtonGetter,
                mailAlertGetter,
            ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordButton.tap()
        return try LoginPasswordScreen()
    }
}
