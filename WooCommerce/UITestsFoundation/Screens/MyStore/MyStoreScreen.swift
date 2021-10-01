import ScreenObject
import XCTest

public final class MyStoreScreen: ScreenObject {

    public let tabBar = TabNavComponent()
    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let periodStatsTable = try! PeriodStatsTable()

    private let settingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["dashboard-settings-button"]
    }

    private var settingsButton: XCUIElement { settingsButtonGetter(app) }

    static var isVisible: Bool {
        guard let screen = try? MyStoreScreen() else { return false }
        return screen.settingsButton.isHittable
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [settingsButtonGetter],
            app: app
        )
    }

    @discardableResult
    public func dismissTopBannerIfNeeded() -> MyStoreScreen {
        let topBannerCloseButton = app.buttons["top-banner-view-dismiss-button"]
        guard topBannerCloseButton.waitForExistence(timeout: 3) else { return self }

        topBannerCloseButton.tap()
        return self
    }

    @discardableResult
    public func openSettingsPane() throws -> SettingsScreen {
        settingsButton.tap()
        return try SettingsScreen()
    }
}
