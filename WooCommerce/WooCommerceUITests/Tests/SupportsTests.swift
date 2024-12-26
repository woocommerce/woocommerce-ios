import UITestsFoundation
import XCTest

final class SupportTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
    }

    // Test ends before tapping the submit button so it doesn't get sent to zendesk
    func test_load_support_screen() throws {
        try PrologueScreen().tapLogIn()
            .tapHelpButton()
            .tapContactSupport()
            .addEmail(email: TestCredentials.emailAddress)
            .verifySubmitButtonDisabled()
            .addSupportContent(subject: TestStrings.supportSubject, message: TestStrings.supportMessage)
            .verifySubmitButtonEnabled()
    }
}
