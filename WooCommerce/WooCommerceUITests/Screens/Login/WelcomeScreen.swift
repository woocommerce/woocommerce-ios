import Foundation
import XCTest

final class WelcomeScreen: BaseScreen {

    private struct ElementStringIDs {
        static let loginButton = "Prologue Log In Button"
    }

    private let logInButton: XCUIElement

    init() {
        logInButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        super.init(element: logInButton)
    }

    func selectLogin() -> LoginEmailScreen {
        logInButton.tap()
        return LoginEmailScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
