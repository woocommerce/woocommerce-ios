import XCTest

final class LoginTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        app.launch()
    }

    func testWordPressLoginLogout() {
        let prologue = PrologueScreen().selectContinueWithWordPress()
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()

            // Log out
            .openSettingsPane()
            .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
            .logOut()

        XCTAssert(prologue.isLoaded())
    }

    func testSiteAddressLoginLogout() {
        let prologue = PrologueScreen().selectSiteAddress()
            .proceedWith(siteUrl: TestCredentials.siteUrl)
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
            //.dismissNotificationAlertIfNeeded()

            // Log out
            .openSettingsPane()
            .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
            .logOut()


        XCTAssert(prologue.isLoaded())
    }
}
