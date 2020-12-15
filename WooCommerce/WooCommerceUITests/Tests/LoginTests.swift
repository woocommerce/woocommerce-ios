import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        app.launch()
    }

//    func testEmailPasswordLoginLogout() {
//        // Log in with email and password
//        WelcomeScreen()
//        .selectLogin()
//        .proceedWith(email: TestCredentials.emailAddress)
//        .proceedWithPassword()
//        .proceedWith(password: TestCredentials.password)
//
//        // Login epilogue
//        .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
//        .continueWithSelectedSite()
//
//        // Log out
//        .openSettingsPane()
//        .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
//        .logOut()
//
//        XCTAssert(WelcomeScreen.isLoaded())
//    }


    //Modified
//    func testEmailPasswordLoginLogout() {
//        // Log in with email and password
//        PrologueScreen()
//        .selectLogin()
//        .proceedWith(email: TestCredentials.emailAddress)
//        .proceedWithPassword()
//        .proceedWith(password: TestCredentials.password)
//
//        // Login epilogue
//        .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
//        .continueWithSelectedSite()
//
//        // Log out
//        .openSettingsPane()
//        .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
//        .logOut()
//
//        XCTAssert(WelcomeScreen.isLoaded())
//    }

    // Unified WordPress.com login/out
    // Replaces testWpcomUsernamePasswordLogin
    func testWpcomLogin() {
        let prologue = PrologueScreen().selectSiteAddress()
            .proceedWithWP(siteUrl: TestCredentials.siteUrl)
            //.proceedWith(username: TestCredentials.emailAddress, password: TestCredentials.password)
            .proceedWith(email: TestCredentials.emailAddress)
            .proceedWith(password: TestCredentials.password)
            .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
            .continueWithSelectedSite()
            //.dismissNotificationAlertIfNeeded()

        //XCTAssert(MySiteScreen().isLoaded())

            // Log out
            .openSettingsPane()
            .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
            .logOut()

        XCTAssert(prologue.isLoaded())
    }
}
