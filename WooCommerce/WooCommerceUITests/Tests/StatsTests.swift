import UITestsFoundation
import XCTest

final class StatsTests: XCTestCase {

    override func setUpWithError() throws {
        try skipTillImplemented()
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()

        try LoginFlow.logInWithWPcom()
    }

    func testStatsScreenLoad() throws {
        try skipTillImplemented()
        try TabNavComponent().goToMyStoreScreen()
    }


    func skipTillImplemented(file: StaticString = #file, line: UInt = #line) throws {
        try XCTSkipIf(true,
            "Skipping until test is properly implemented", file: file, line: line)
    }
}
