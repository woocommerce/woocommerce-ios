import ScreenObject
import XCTest

public final class LoginEmailScreen: ScreenObject {

    private let emailButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Login Email Address"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Login Email Next Button"]
    }

    private let siteAddressButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Self Hosted Login Button"]
    }

    private let emailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Self Hosted Login Button"]
    }

    private var emailButton: XCUIElement { emailButtonGetter(app) }
    private var nextButton: XCUIElement { nextButtonGetter(app) }
    private var siteAddressButton: XCUIElement { siteAddressButtonGetter(app) }
    private var emailTextField: XCUIElement { emailTextFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                emailButtonGetter,
                emailTextFieldGetter,
                nextButtonGetter,
                siteAddressButtonGetter
            ],
            app: app
        )
    }

    func proceedWith(email: String) throws -> LinkOrPasswordScreen {
        emailButton.enterText(text: email)
        nextButton.tap()

        return try LinkOrPasswordScreen()
    }

    func goToSiteAddressLogin() throws -> LoginSiteAddressScreen {
        siteAddressButton.tap()
        return try LoginSiteAddressScreen()
    }

    func isEmailEntered() -> Bool {
        return emailTextField.value != nil
    }
}
