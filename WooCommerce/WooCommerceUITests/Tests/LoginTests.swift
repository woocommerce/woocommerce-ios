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

    // Test disabled - Pending update of the Settings flow
    // Login with Store Address and log out.
    func test_site_address_login_logout() throws {
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

    // Test disabled - Pending update of the Settings flow
    // Login with WordPress.com account and log out
    func test_WordPress_login_logout() throws {
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

    func test_WordPress_unsuccessfull_login() throws {
        _ = try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
