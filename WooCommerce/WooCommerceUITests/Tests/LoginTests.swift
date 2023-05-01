import UITestsFoundation
import XCTest

final class LoginTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
    }

    func test_site_address_login_logout() throws {
        // do not test this case if site address login is not available
        guard try PrologueScreen().isSiteAddressLoginAvailable() else {
            return
        }
        try PrologueScreen()
            .tapLogIn()
            .proceedWith(siteUrl: TestCredentials.siteUrl)
            .proceedWith(email: TestCredentials.emailAddress)
            .enterValidPassword(password: TestCredentials.password)

        try TabNavComponent()
            .goToMenuScreen()
            .verifySelectedStoreDisplays(storeTitle: TestCredentials.storeName, storeURL: TestCredentials.siteUrlHost)
            .openSettingsPane()
            .logOut()
            .verifyPrologueScreenLoaded()
    }

    func test_WordPress_login_logout() throws {
        // do not test this case if wpcom login is not available
        guard try PrologueScreen().isWPComLoginAvailable() else {
            return
        }
        try PrologueScreen().tapContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)

        try LoginEpilogueScreen()
            .verifyEpilogueDisplays(email: "e2eflowtestingmobile@example.com", siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()

        try TabNavComponent()
            .goToMenuScreen()
            .verifySelectedStoreDisplays(storeTitle: TestCredentials.storeName, storeURL: TestCredentials.siteUrlHost)
            .openSettingsPane()
            .logOut()
            .verifyPrologueScreenLoaded()
    }

    func test_WordPress_unsuccessfull_login() throws {
        // do not test this case if wpcom login is not available
        guard try PrologueScreen().isWPComLoginAvailable() else {
            return
        }
        try PrologueScreen().tapContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .enterInvalidPassword(password: "invalidPswd")
            .verifyLoginError()
    }
}
