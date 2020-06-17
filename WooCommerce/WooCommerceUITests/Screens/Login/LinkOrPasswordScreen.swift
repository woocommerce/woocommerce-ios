import Foundation
import XCTest

private struct ElementStringIDs {
    static let passwordOption = "Use Password"
    static let linkButton = "Send Link Button"
    static let backToLoginScreenButton = "Back"
}

final class LinkOrPasswordScreen: BaseScreen {
    private let passwordOption: XCUIElement
    private let linkButton: XCUIElement
    private let backToLoginScreenButton: XCUIElement

    init() {
        let app = XCUIApplication()
        backToLoginScreenButton = app.buttons[ElementStringIDs.backToLoginScreenButton]
        passwordOption = app.buttons[ElementStringIDs.passwordOption]
        linkButton = app.buttons[ElementStringIDs.linkButton]

        super.init(element: passwordOption)
        XCTAssert(passwordOption.waitForExistence(timeout: 3))
        XCTAssert(linkButton.waitForExistence(timeout: 3))
        XCTAssert(backToLoginScreenButton.waitForExistence(timeout: 3))
    }

    func proceedWithPassword() -> LoginPasswordScreen {
        passwordOption.tap()

        return LoginPasswordScreen()
    }

    func proceedWithLink() -> LoginCheckMagicLinkScreen {
        linkButton.tap()

        return LoginCheckMagicLinkScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.passwordOption].exists && XCUIApplication().buttons[ElementStringIDs.passwordOption].isHittable
    }

    func goBack() -> LoginEmailScreen {
        backToLoginScreenButton.tap()
        return LoginEmailScreen()
    }

}
