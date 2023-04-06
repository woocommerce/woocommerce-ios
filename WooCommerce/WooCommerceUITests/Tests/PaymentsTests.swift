import UITestsFoundation
import XCTest

final class PaymentsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()
    }

    func test_load_chipper_card_reader_manual() throws {
        try TabNavComponent().goToMenuScreen()
            .goToPaymentsScreen()
            .tapCardReaderManuals()
            .tapChipperManual()
            .verifyChipperManualLoadedOnWebView()
    }

    func test_load_payments_universal_link() throws {
        let paymentsLink = "https://woocommerce.com/mobile/payments"

        ExternalAppScreen().openUniversalLinkFromRemindersApp(link: paymentsLink)
        try PaymentsScreen().verifyPaymentsScreenLoaded()
    }
}
