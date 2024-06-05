import UITestsFoundation
import XCTest

final class PaymentsTests: XCTestCase {

    override func setUpWithError() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()

        try TabNavComponent().goToMenuScreen()
            .goToPaymentsScreen()
    }

    func test_load_chipper_card_reader_manual() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        try PaymentsScreen().tapCardReaderManuals()
            .tapChipperManual()
            .verifyChipperManualLoadedInWebView()
    }

    func test_load_learn_more_link() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        try PaymentsScreen().tapLearnMoreIPPLink()
            .verifyIPPDocumentationLoadedInWebView()
    }

    func test_complete_cash_simple_payment() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        try PaymentsScreen().tapCollectPayment()
            .enterPaymentAmount("5")
            .takeCashPayment()
            .verifyOrderCompletedToastDisplayed()
            .verifyPaymentsScreenLoaded()
    }
}
