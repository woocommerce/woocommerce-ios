import XCTest

class LoginTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        app.launch()
    }

    func testEmailPasswordLoginLogout() {
        // Log in with email and password
        WelcomeScreen()
        .selectLogin()
        .proceedWith(email: TestCredentials.emailAddress)
        .proceedWithPassword()
        .proceedWith(password: TestCredentials.password)

        // Login epilogue
        .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
        .continueWithSelectedSite()

        // Log out
        .openSettingsPane()
        .verifySelectedStoreDisplays(siteUrl: TestCredentials.siteUrl, displayName: TestCredentials.displayName)
        .logOut()

        XCTAssert(WelcomeScreen.isLoaded())
    }

    func testLoginOptionsArePresent() {
        //verify tapping "Log in" will show options to enter a WordPress.com email, log in with Google, or enter your site address.
        WelcomeScreen()
        .selectLogin()
        .openHelpMenu()
        //will add .sendEmailToSupport once I have some questions answered about that
        .closeHelpMenu()

        //verify all login options exist
        .emailLoginOption()
        .siteAddressLoginOption()
        .googleLoginOption()
        .backToWelcomeScreen()

        XCTAssert(WelcomeScreen.isLoaded())

    }
}
