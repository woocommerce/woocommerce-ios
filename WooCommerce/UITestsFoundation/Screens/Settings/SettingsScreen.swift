import ScreenObject
import XCTest

public final class SettingsScreen: ScreenObject {

    private let selectedStoreNameGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells.staticTexts["headline-label"]
    }

    private let selectedSiteUrlGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells.staticTexts["body-label"]
    }

    private let logOutButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["settings-log-out-button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                selectedStoreNameGetter,
                selectedSiteUrlGetter,
                logOutButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    func goBackToMyStore() throws -> MyStoreScreen {
        navBackButton.tap()
        return try MyStoreScreen()
    }

    @discardableResult
    public func logOut() throws -> PrologueScreen {
        logOutButtonGetter(app).tap()

        let logOutAlert = app.alerts.element(boundBy: 0)

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonAxisX {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return try PrologueScreen()
    }
}

/// Assertions
extension SettingsScreen {

    public func verifySelectedStoreDisplays(storeName expectedStoreName: String, siteUrl expectedSiteUrl: String) -> SettingsScreen {
        let actualStoreName = selectedStoreNameGetter(app).label
        let expectedSiteUrl = expectedSiteUrl.replacingOccurrences(of: "http://", with: "")
        let actualSiteUrl = selectedSiteUrlGetter(app).label

        XCTAssertEqual(expectedStoreName, actualStoreName,
                       "Expected display name '\(expectedStoreName)' but '\(actualStoreName)' was displayed instead.")
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl,
                       "Expected site URL \(expectedSiteUrl) but \(actualSiteUrl) was displayed instead.")
        return self
    }
}
