import XCTest

class WooCommerceScreenshots: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
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

            // Enable Products
            .openSettingsPane().openBetaFeatures()
            .enableProducts()
            .goBackToSettingsScreen().goBackToMyStore()

            // My Store
            .dismissTopBannerIfNeeded()
            .then { ($0 as! MyStoreScreen).periodStatsTable.switchToYearsTab() }
            .thenTakeScreenshot(named: "order-dashboard")

            // Orders
            .tabBar.gotoOrdersScreen()
            .thenTakeScreenshot(named: "order-list")
            .selectOrder(atIndex: 0)
            .thenTakeScreenshot(named: "order-detail")
            .goBackToOrdersScreen()

            .openSearchPane()
            .thenTakeScreenshot(named: "order-search")
            .cancel()

            // Reviews
            .tabBar.gotoReviewsScreen()
            .thenTakeScreenshot(named: "review-list")
            .selectReview(atIndex: 3)
            .thenTakeScreenshot(named: "review-details")
            .goBackToReviewsScreen()

            // Products
            .tabBar.gotoProductsScreen()
            .collapseTopBannerIfNeeded()
            .thenTakeScreenshot(named: "product-list")
            .selectProduct(atIndex: 1)
            .thenTakeScreenshot(named: "product-details")
    }
}

fileprivate var screenshotCount = 0

extension BaseScreen {

    @discardableResult
    func thenTakeScreenshot(named title: String) -> Self {
        screenshotCount += 1

        let mode = isDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
