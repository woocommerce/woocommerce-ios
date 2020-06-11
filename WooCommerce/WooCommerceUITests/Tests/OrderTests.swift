import XCTest

class OrderTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["disable-animations", "mocked-wpcom-api"]
        app.launch()

        Flows.loginIfNeeded(email: TestCredentials.emailAddress, password: TestCredentials.password)
            .tabBar.gotoOrdersScreen()
    }

    func testFulfillOrder() {
        OrdersScreen()
            .selectOrder(atIndex: 0)
            .beginFulfillment()
            .canAddTracking()
            .completeFulfillment()
            .goBackToOrdersScreen()
    }

    func testAddOrderNote() {
        let noteText = "This is an order note."
        OrdersScreen()
            .selectOrder(atIndex: 0)
            .selectAddNote()
            .addNote(withText: noteText, sendEmail: .on)
            .goBackToOrdersScreen()
    }

    func testAddOrderTracking() {
        OrdersScreen()
            .selectOrder(atIndex: 0)
            .addTracking(withCarrier: "USPS", andTrackingNumber: "tracking123")
            .goBackToOrdersScreen()
    }

    override func tearDown() {
        while !OrdersScreen.isVisible {
            navBackButton.tap()
        }
    }
}
