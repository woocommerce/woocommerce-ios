import ScreenObject
import XCTest

public final class SettingsScreen: ScreenObject {
    private let settingsNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Settings"]
    }

    private let betaFeaturesGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["settings-beta-features-button"]
    }

    private let logOutButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["settings-log-out-button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                settingsNavigationBarGetter,
                betaFeaturesGetter
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

    /// Navigates to the Experimental Features screen.
    /// - Returns: Experimental Features screen object.
    @discardableResult
    public func goToExperimentalFeatures() throws -> BetaFeaturesScreen {
        betaFeaturesGetter(app).tap()
        return try BetaFeaturesScreen()
    }
}
