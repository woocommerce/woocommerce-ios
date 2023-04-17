import ScreenObject
import XCTest

public final class HelpScreen: ScreenObject {

    private let contactSupportButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Contact Support"]
    }

    private let emailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Email"]
    }

    private let helpListFirstOptionGetter: (XCUIApplication) -> XCUIElement = {
        $0.scrollViews.element.staticTexts.element(boundBy: 1)
    }

    private let helpNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Help"]
    }

    private let messageTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.scrollViews.element.textViews.element(boundBy: 0)
    }

    private let okButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["OK"]
    }

    private let subjectTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.scrollViews.element.textFields.element(boundBy: 0)
    }

    private let submitButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Submit Support Request"]
    }

    private var contactSupportButton: XCUIElement { contactSupportButtonGetter(app) }
    private var emailTextField: XCUIElement { emailTextFieldGetter(app) }
    private var helpListFirstOption: XCUIElement { helpListFirstOptionGetter(app) }
    private var helpNavigationBar: XCUIElement { helpNavigationBarGetter(app) }
    private var messageTextField: XCUIElement { messageTextFieldGetter(app) }
    private var okButton: XCUIElement { okButtonGetter(app) }
    private var subjectTextField: XCUIElement { subjectTextFieldGetter(app) }
    private var submitButton: XCUIElement { submitButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: helpNavigationBarGetter,
            app: app
        )
    }

    public func tapContactSupport() throws -> Self {
        contactSupportButton.tap()

        return self
    }

    public func addEmail(email: String) throws -> Self {
        emailTextField.enterText(text: email)
        okButton.tap()

        return self
    }

    public func addSupportContent(subject: String, message: String) throws -> Self {
        helpListFirstOption.tap()
        subjectTextField.enterText(text: subject)
        messageTextField.enterText(text: message)

        return self
    }

    public func verifySubmitButtonDisabled() throws -> Self {
        XCTAssertTrue(!submitButton.isEnabled)
        return self
    }

    public func verifySubmitButtonEnabled() throws {
        XCTAssertTrue(submitButton.isEnabled)
    }
}
