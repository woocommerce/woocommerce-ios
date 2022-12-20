import ScreenObject
import XCTest

public final class LoginEmailScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
              expectedElementGetters: [
                  // swiftlint:disable opening_brace
                  { $0.buttons["Login Email Address"] },
                  { $0.buttons["Login Email Next Button"] },
                  { $0.buttons["Self Hosted Login Button"] }
                  // swiftlint:enable opening_brace
              ],
            app: app
        )
    }

    func proceedWith(email: String) throws -> LinkOrPasswordScreen {
        app.buttons["Login Email Address"].enterText(text: email)
        app.buttons["Login Email Next Button"].tap()

        return try LinkOrPasswordScreen()
    }

    func goToSiteAddressLogin() throws -> LoginSiteAddressScreen {
        app.buttons["Self Hosted Login Button"].tap()

        return try LoginSiteAddressScreen()
    }

    func isEmailEntered() -> Bool {
        let emailTextField = app.textFields["Login Email Address"]
        return emailTextField.value != nil
    }
}
