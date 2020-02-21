import Foundation
import XCTest

class MyStoreScreen: BaseScreen {

    struct ElementStringIDs {
        static let topBannerCloseButton = "top-banner-view-dismiss-button"
        static let settingsButton = "dashboard-settings-button"
    }

    let tabBar = TabNavComponent()
    let periodStatsTable = PeriodStatsTable()
    let settingsButton: XCUIElement
    let topBannerCloseButton: XCUIElement

    static var isVisible: Bool {
        let settingsButton = XCUIApplication().buttons[ElementStringIDs.settingsButton]
        return settingsButton.exists && settingsButton.isHittable
    }

    init() {
        settingsButton = XCUIApplication().buttons[ElementStringIDs.settingsButton]
        topBannerCloseButton = XCUIApplication().buttons[ElementStringIDs.topBannerCloseButton]

        super.init(element: settingsButton)
    }

    func dismissTopBannerIfNeeded() -> MyStoreScreen {

        if topBannerCloseButton.waitForExistence(timeout: 3) {
            topBannerCloseButton.tap()
        }

        return self
    }

    func goToSettings() -> SettingsScreen {
        settingsButton.tap()

        return SettingsScreen()
    }
}
