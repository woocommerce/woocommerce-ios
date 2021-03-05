import XCTest

class OrdersScreenTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        
        //comment out when testing from simulator already logged-in state:
        // UI tests must launch the application that they test.
        // let app = XCUIApplication()
        //comment out when testing without mocks:
        // app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api"]
        // app.launch()
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
        //Select an order and verify the sections of the single order screen load.
        let singleOrder = TabNavComponent().gotoOrdersScreen().selectOrder(atIndex: 0)
        XCTAssert(singleOrder.isLoaded())
    }
}
