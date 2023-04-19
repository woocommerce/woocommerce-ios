import UITestsFoundation
import XCTest

final class UniversalLinksTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
    }

    func test_load_payments_universal_link() throws {
        try LoginFlow.login()

        try ExternalAppScreen().openUniversalLinkFromSafariApp(linkedScreen: "payments")
        try PaymentsScreen().verifyPaymentsScreenLoaded()
    }

    func test_load_orders_universal_link() throws {
        // run test only on iPhone, on iPad there's an issue where the incorrect order is opened
        if UIDevice.current.userInterfaceIdiom == .phone {
            try LoginFlow.login()
            let order = try GetMocks.readSingleOrderData()

            try ExternalAppScreen().openUniversalLinkFromSafariApp(linkedScreen: "orders")
            try SingleOrderScreen().verifySingleOrder(order: order)
        }
    }
}
