import ScreenObject
import XCTest

public final class MyStoreScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()
    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let periodStatsTable = try! PeriodStatsTable()

    static var isVisible: Bool {
        (try? MyStoreScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["Your WooCommerce Store"] }],
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
}
