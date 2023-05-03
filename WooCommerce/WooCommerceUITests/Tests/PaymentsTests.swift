import UITestsFoundation
import XCTest

final class PaymentsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()

        try TabNavComponent().goToMenuScreen()
            .goToPaymentsScreen()
    }

    func test_load_chipper_card_reader_manual() throws {
        try PaymentsScreen().tapCardReaderManuals()
            .tapChipperManual()
            .verifyChipperManualLoadedInWebView()
    }

    func test_load_learn_more_link() throws {
        try PaymentsScreen().tapLearnMoreIPPLink()
            .verifyIPPDocumentationLoadedInWebView()
    }

    func test_complete_cash_simple_payment() throws {
        try PaymentsScreen().tapCollectPayment()
            .enterPaymentAmount()
            .takeCashPayment()
            .verifyOrderCompletedToastDisplayed()
            .verifyPaymentsScreenLoaded()
    }
}
