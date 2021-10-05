import UITestsFoundation
import ScreenObject
import XCTest

final class MyStoreScreen: ScreenObject {

    let tabBar = TabNavComponent()
    let periodStatsTable = PeriodStatsTable()

    private let settingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["dashboard-settings-button"]
    }

    private var settingsButton: XCUIElement { settingsButtonGetter(app) }

    static var isVisible: Bool {
        guard let screen = try? MyStoreScreen() else { return false }
        return screen.settingsButton.isHittable
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [settingsButtonGetter],
            app: app
        )
    }

    @discardableResult
    func dismissTopBannerIfNeeded() -> MyStoreScreen {
        let topBannerCloseButton = app.buttons["top-banner-view-dismiss-button"]
        guard topBannerCloseButton.waitForExistence(timeout: 3) else { return self }

        topBannerCloseButton.tap()
        return self
    }

    @discardableResult
    func openSettingsPane() -> SettingsScreen {
        settingsButton.tap()
        return SettingsScreen()
    }
}
