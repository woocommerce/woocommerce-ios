import XCTest

class WooCommerceScreenshots: XCTestCase {

    override func setUp() {

        continueAfterFailure = false

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }
    }

    func testScreenshots() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations"]
        app.launch()

        WelcomeScreen()
            .selectLogin()
            .proceedWith(email: "")
            .proceedWithPassword()
            .proceedWith(password: "")
            .continueWithSelectedSite()
            .dismissTopBannerIfNeeded()
    }
}
