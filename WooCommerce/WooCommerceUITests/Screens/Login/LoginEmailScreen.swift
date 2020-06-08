import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.LoginEmailView"
    static let emailTextField = "Login Email Address"
    static let nextButton = "Login Email Next Button"
    static let siteAddressButton = "Self Hosted Login Button"
    static let helpButton = "Help Button"
    static let contactSupport = "Contact Support"
    static let googleLoginButton = "Log in with Google"
    static let dismissButton = "Dismiss"
    static let backToWelcomeScreenButton = "Back Button"
}

final class LoginEmailScreen: BaseScreen {
    private let navBar: XCUIElement
    private let emailTextField: XCUIElement
    private let nextButton: XCUIElement
    private let siteAddressButton: XCUIElement
    private let helpButton: XCUIElement
    private let contactSupport: XCUIElement
    private let googleLoginButton: XCUIElement
    private let backToWelcomeScreenButton: XCUIElement
    private let dismissButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]
        siteAddressButton = app.buttons[ElementStringIDs.siteAddressButton]
        helpButton = app.buttons[ElementStringIDs.helpButton]
        contactSupport = app.cells[ElementStringIDs.contactSupport]
        googleLoginButton = app.buttons[ElementStringIDs.googleLoginButton]
        backToWelcomeScreenButton = app.buttons[ElementStringIDs.backToWelcomeScreenButton]
        dismissButton = app.buttons[ElementStringIDs.dismissButton]

        super.init(element: emailTextField)
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

    func openHelpMenu() -> Bool {
        helpButton.tap()
        let contactSupport = XCUIApplication().cells[ElementStringIDs.contactSupport]
        return contactSupport.exists && contactSupport.isHittable
    }

    func closeHelpMenu() -> LoginEmailScreen {
        dismissButton.tap()
        return LoginEmailScreen()

    }
    func emailLoginOption() ->Bool {
        let emailLogin = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return emailLogin.exists && emailLogin.isHittable
    }

    func siteAddressLoginOption() -> Bool {
        let siteAddressLogin = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]
        return siteAddressLogin.exists && siteAddressLogin.isHittable
    }

    func googleLoginOption() -> Bool {
        let googleLogin = XCUIApplication().buttons[ElementStringIDs.googleLoginButton]
        return googleLogin.exists && googleLoginButton.isHittable
    }

    func BackToWelcomeScreen() -> WelcomeScreen {
        backToWelcomeScreenButton.tap()
        return WelcomeScreen()
    }
}
