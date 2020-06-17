import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.LoginEmailView"
    static let emailTextField = "Login Email Address"
    static let nextButton = "Login Email Next Button"
    static let siteAddressButton = "Self Hosted Login Button"
    static let helpButton = "Help Button"
    static let googleLoginButton = " Log in with Google."
    static let backToWelcomeScreenButton = "Back"
}

final class LoginEmailScreen: BaseScreen {
    private let navBar: XCUIElement
    private let emailTextField: XCUIElement
    private let nextButton: XCUIElement
    private let siteAddressButton: XCUIElement
    private let helpButton: XCUIElement
    private let googleLoginButton: XCUIElement
    private let backToWelcomeScreenButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]
        siteAddressButton = app.buttons[ElementStringIDs.siteAddressButton]
        helpButton = app.buttons[ElementStringIDs.helpButton]
        googleLoginButton = app.buttons[ElementStringIDs.googleLoginButton]
        backToWelcomeScreenButton = app.buttons[ElementStringIDs.backToWelcomeScreenButton]

        super.init(element: emailTextField)
        XCTAssert(emailTextField.waitForExistence(timeout: 3))
        XCTAssert(googleLoginButton.waitForExistence(timeout: 3))
        XCTAssert(emailTextField.waitForExistence(timeout: 3))
    }

    func proceedWith(email: String) -> LinkOrPasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return LinkOrPasswordScreen()
    }

    func goToSiteAddressLogin() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        let expectedElement = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return expectedElement.exists && expectedElement.isHittable
    }

    static func isEmailEntered() -> Bool {
        let emailTextField = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return emailTextField.value != nil
    }

    func openHelpMenu() -> HelpScreen {
        helpButton.tap()
        return HelpScreen()
    }

    func goBackToWelcomeScreen() -> WelcomeScreen {
        backToWelcomeScreenButton.tap()
        return WelcomeScreen()
    }
}
