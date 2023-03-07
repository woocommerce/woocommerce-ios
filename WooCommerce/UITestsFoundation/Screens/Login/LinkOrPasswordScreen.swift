import ScreenObject
import XCTest

public final class LinkOrPasswordScreen: ScreenObject {

    private let passwordButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }

    private let sendLinkButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Send Link Button"]
    }

    private var passwordButton: XCUIElement { passwordButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordButtonGetter,
                sendLinkButtonGetter
            ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordButton.tap()
        return try LoginPasswordScreen()
    }

    func proceedWithLink() throws -> LoginCheckMagicLinkScreen {
        passwordButton.tap()
        return try LoginCheckMagicLinkScreen()
    }
}
