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
        setupSnapshot(app)

        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        app.launch()

        WelcomeScreen()
            .selectLogin()
            .proceedWith(email: ScreenshotCredentials.emailAddress)
            .proceedWithPassword()
            .proceedWith(password: ScreenshotCredentials.password)
            .continueWithSelectedSite()
            .dismissTopBannerIfNeeded()
            .then { ($0 as! MyStoreScreen).periodStatsTable.switchToYearsTab() }
            .thenTakeScreenshot(4, named: "view-store-data")

            // Orders
            .tabBar.gotoOrdersScreen()
            .thenTakeScreenshot(1, named: "view-and-manage-orders")
            .selectOrder(atIndex: 0)
            .thenTakeScreenshot(2, named: "track-order-status")
            .goBackToOrdersScreen()

            .openSearchPane()
            .thenTakeScreenshot(3, named: "look-up-specific-orders")
            .cancel()

            .tabBar.gotoReviewsScreen()
            .selectReview(atIndex: 3)
            .thenTakeScreenshot(5, named: "get-notified-about-customer-reviews")
            .goBackToReviewsScreen()

    }
}

extension BaseScreen {
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = isDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
