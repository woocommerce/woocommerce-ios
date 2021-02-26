import XCTest

class OrdersScreenTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        //comment out when testing without mocks:
        //app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        // comment out when testing from simulator already logged-in state:
        //app.launch()
    }

    // Login, check that SingleOrderScreen loads
    func test_load_single_order_screen() {
        //Login and go to My Store screen
        //comment out when testing without mocks
  /*      let prologue = PrologueScreen().selectSiteAddress()
  *          .proceedWith(siteUrl: TestCredentials.siteUrl)
  *          .proceedWith(email: TestCredentials.emailAddress)
  *          .proceedWith(password: TestCredentials.password)
  *          .verifyEpilogueDisplays(displayName: TestCredentials.displayName, siteUrl: TestCredentials.siteUrl)
  *          .continueWithSelectedSite()
  */

        // Navigate to orders screen
        // Find tabNavComponent, tap Orders button using gotoOrdersScreen function
        let tabNavComponent = TabNavComponent()
        tabNavComponent.gotoOrdersScreen()

        // check that Orders screen is loaded
        let orderScreen = OrdersScreen()
        XCTAssert(orderScreen.isLoaded(), "Orders screen isn't loaded.")

        // Select an order to get to SingleOrderScreen
        // Assert that singleOrderScreen is loaded. This will check all the items asserted in singleOrderScreen's init.
        orderScreen.selectOrder(atIndex: 0)
        let singleOrderScreen = SingleOrderScreen()
        XCTAssert(singleOrderScreen.isLoaded(), "Single Order Screen isn't loaded.")
    }
}
