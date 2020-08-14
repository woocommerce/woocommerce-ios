import Foundation
import XCTest

final class WelcomeScreen: BaseScreen {

    private struct ElementStringIDs {
        static let loginButton = "Prologue Log In Button"
        static let loginWithEmailButton = "Log in with Email Button"
    }

    private let logInButton: XCUIElement
    private let logInWithEmailButton: XCUIElement

    init() {
        logInButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        logInWithEmailButton = XCUIApplication().buttons[ElementStringIDs.loginWithEmailButton]
        super.init(element: logInButton)
    }

    func selectLogin() -> LoginEmailScreen {
        logInButton.tap()
        logInWithEmailButton.tap()
        return LoginEmailScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
