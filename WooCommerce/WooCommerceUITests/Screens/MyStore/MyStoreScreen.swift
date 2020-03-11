import Foundation
import XCTest

final class MyStoreScreen: BaseScreen {

    struct ElementStringIDs {
        static let topBannerCloseButton = "top-banner-view-dismiss-button"
        static let settingsButton = "dashboard-settings-button"
    }

    let tabBar = TabNavComponent()
    let periodStatsTable = PeriodStatsTable()
    private let settingsButton: XCUIElement
    private let topBannerCloseButton: XCUIElement

    static var isVisible: Bool {
        let settingsButton = XCUIApplication().buttons[ElementStringIDs.settingsButton]
        return settingsButton.exists && settingsButton.isHittable
    }

    init() {
        settingsButton = XCUIApplication().buttons[ElementStringIDs.settingsButton]
        topBannerCloseButton = XCUIApplication().buttons[ElementStringIDs.topBannerCloseButton]

        super.init(element: settingsButton)

        XCTAssert(settingsButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func dismissTopBannerIfNeeded() -> MyStoreScreen {

        if topBannerCloseButton.waitForExistence(timeout: 3) {
            topBannerCloseButton.tap()
        }

        return self
    }

    @discardableResult
    func openSettingsPane() -> SettingsScreen {
        settingsButton.tap()
        return SettingsScreen()
    }
}
