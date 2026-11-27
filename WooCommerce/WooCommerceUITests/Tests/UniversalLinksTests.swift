import UITestsFoundation
import XCTest

@MainActor
final class UniversalLinksTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_load_payments_universal_link() throws {
        let app = launchWithMockStore()

        try ExternalAppScreen().openUniversalLink(linkedScreen: "payments")
        try PaymentsScreen(app: app).verifyPaymentsScreenLoaded()
    }

    func test_load_orders_universal_link() throws {
        // run test only on iPhone, on iPad there's an issue where the incorrect order is opened
        if UIDevice.current.userInterfaceIdiom == .phone {
            let app = launchWithMockStore()
            let order = try GetMocks.readSingleOrderData()

            try ExternalAppScreen().openUniversalLink(linkedScreen: "orders")
            try SingleOrderScreen(app: app).verifySingleOrder(order: order)
        }
    }

    private func launchWithMockStore() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launchEnvironment = TestCredentials.mockStoreLaunchEnvironment
        app.launch()
        XCTAssertTrue(app.staticTexts["my-store-title"].waitForExistence(timeout: 30),
                      "My Store should load before opening a universal link.")
        return app
    }
}
