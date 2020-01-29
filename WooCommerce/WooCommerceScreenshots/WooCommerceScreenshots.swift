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

        app.launchArguments = ["logout-at-launch", "disable-animations"]
        app.launch()

        WelcomeScreen()
            .selectLogin()
            .proceedWith(email: ApiCredentials.screenshotEmailAddress)
            .proceedWithPassword()
            .proceedWith(password: ApiCredentials.screenshotPassword)
            .continueWithSelectedSite()
            .dismissTopBannerIfNeeded()
            .then { ($0 as! MyStoreScreen).periodStatsTable.switchToYearsTab() }
            .then { snapshot("4-view-store-data") }

            // Orders
            .tabBar.gotoOrdersScreen()
            .then { snapshot("1-view-and-manage-orders") }
            .selectOrder(atIndex: 0)
            .then { snapshot("2-track-order-status") }
            .goBackToOrdersScreen()

            .openSearchPane()
            .then { snapshot("3-look-up-specific-orders") }
            .cancel()

            .tabBar.gotoReviewsScreen()
            .selectReview(atIndex: 3)
            .then { snapshot("5-get-notified-about-customer-reviews") }
            .goBackToReviewsScreen()
    }
}
