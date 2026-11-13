import UITestsFoundation
import XCTest

@MainActor
final class PaymentsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // XCTest runs synchronous setup on the main thread, where XCUI automation must stay.
        try MainActor.assumeIsolated {

            let app = XCUIApplication()
            app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
            app.launch()
            try LoginFlow.login()

            try TabNavComponent().goToMenuScreen()
                .goToPaymentsScreen()
        }
    }

    func test_load_chipper_card_reader_manual() throws {
        try PaymentsScreen().tapCardReaderManuals()
            .tapChipperManual()
            .verifyChipperManualLoadedInWebView()
    }

    func test_load_learn_more_link() throws {
        try PaymentsScreen().clickLearnMoreIPPLink()
            .verifyIPPDocumentationLoadedInWebView()
    }
}
