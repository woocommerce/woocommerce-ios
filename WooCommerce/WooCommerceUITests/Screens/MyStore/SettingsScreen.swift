import Foundation
import XCTest

final class SettingsScreen: BaseScreen {

    struct ElementStringIDs {
        static let navbar = "Settings"
        static let headlineLabel = "headline-label"
        static let bodyLabel = "body-label"
        static let logOutButton = "log-out-button"
    }

    private let navbar: XCUIElement
    private let selectedSiteUrl: XCUIElement
    private let selectedDisplayName: XCUIElement
    private let logOutButton: XCUIElement
    private let logOutAlert: XCUIElement

    init() {
        let app = XCUIApplication()
        selectedSiteUrl = app.cells.staticTexts[ElementStringIDs.headlineLabel]
        selectedDisplayName = app.cells.staticTexts[ElementStringIDs.bodyLabel]
        navbar = app.navigationBars[ElementStringIDs.navbar]
        logOutButton = app.cells[ElementStringIDs.logOutButton]
        logOutAlert = app.alerts.element(boundBy: 0)

        super.init(element: navbar)

        XCTAssert(logOutButton.waitForExistence(timeout: 3))
    }

    func verifySelectedStoreDisplays(siteUrl expectedSiteUrl: String, displayName expectedDisplayName: String) -> SettingsScreen {
        let expectedSiteUrl = expectedSiteUrl.replacingOccurrences(of: "http://", with: "")
        let actualSiteUrl = selectedSiteUrl.label
        let actualDisplayName = selectedDisplayName.label

        XCTAssertEqual(expectedSiteUrl, actualSiteUrl,
                       "Expected site URL \(expectedSiteUrl) but \(actualSiteUrl) was displayed instead.")
        XCTAssertEqual(expectedDisplayName, actualDisplayName,
                       "Expected display name '\(expectedDisplayName)' but '\(actualDisplayName)' was displayed instead.")

        return self
    }

    @discardableResult
    func logOut() -> WelcomeScreen {
        logOutButton.tap()

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonXAxis {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return WelcomeScreen()
    }
}
