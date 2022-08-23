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

    func test_site_address_login_logout() throws {
        try PrologueScreen()
            .selectSiteAddress()
            .proceedWith(siteUrl: TestCredentials.siteUrl)
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)

        // Log out and verify
        try TabNavComponent()
            .goToMenuScreen()
            .verifySelectedStoreDisplays(storeTitle: TestCredentials.storeName, storeURL: TestCredentials.siteUrl)
            .openSettingsPane()
            .logOut()
            .verifyPrologueScreenLoaded()
    }

    func test_WordPress_login_logout() throws {

        try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)

        try LoginEpilogueScreen()
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()

        // Log out and verify
        try TabNavComponent()
            .goToMenuScreen()
            .verifySelectedStoreDisplays(storeTitle: TestCredentials.storeName, storeURL: TestCredentials.siteUrl)
            .openSettingsPane()
            .logOut()
            .verifyPrologueScreenLoaded()
    }

    func test_WordPress_unsuccessfull_login() throws {
        _ = try PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .tryProceed(password: "invalidPswd")
            .verifyLoginError()
    }
}
