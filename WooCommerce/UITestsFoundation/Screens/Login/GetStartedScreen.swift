import ScreenObject
import XCTest

public final class GetStartedScreen: ScreenObject {

    private let emailFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Email address"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Get Started Email Continue Button"]
    }

    private var emailField: XCUIElement { emailFieldGetter(app) }
    private var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                emailFieldGetter,
                continueButtonGetter
            ],
            app: app
        )
    }

    public func proceedWith(email: String) throws -> PasswordScreen {
        emailField.enterText(text: email)
        continueButton.tap()

        return try PasswordScreen()
    }

    func isEmailEntered() -> Bool {
        return emailField.value != nil
    }
}
