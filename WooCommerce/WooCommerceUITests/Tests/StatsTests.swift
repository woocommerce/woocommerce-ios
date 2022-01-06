import UITestsFoundation
import XCTest

final class StatsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()

        try LoginFlow.logInWithWPcom()
    }

    // Disabled test, added to test stats mocks. To be updated into a real test later.
    func testStatsScreenLoad() throws {
        try TabNavComponent().goToMyStoreScreen()
        sleep(1000)
    }
}
