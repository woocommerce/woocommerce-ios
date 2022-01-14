import UITestsFoundation
import XCTest

final class LoginTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
    }

    // Login with Store Address and log out.
    func testSiteAddressLoginLogout() throws {
        let prologue = try PrologueScreen().selectSiteAddress()
            .proceedWith(siteUrl: TestCredentials.siteUrl)
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()

            // Log out
        try TabNavComponent()
            .goToMenuScreen()
            .openSettingsPane()
            .verifySelectedStoreDisplays(storeName: TestCredentials.storeName, siteUrl: TestCredentials.siteUrl)
            .logOut()

        XCTAssert(prologue.isLoaded)
    }

    //Login with WordPress.com account and log out
    func testWordPressLoginLogout() throws {
        let prologue = try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()

            // Log out
        try TabNavComponent()
            .goToMenuScreen()
            .openSettingsPane()
            .verifySelectedStoreDisplays(storeName: TestCredentials.storeName, siteUrl: TestCredentials.siteUrl)
            .logOut()

        XCTAssert(prologue.isLoaded)
    }

    func testWordPressUnsuccessfullLogin() throws {
        _ = try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
