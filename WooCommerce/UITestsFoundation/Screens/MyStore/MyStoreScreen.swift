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

    func tapTimeframeTab(timeframeId: String) -> MyStoreScreen {
        app.cells[timeframeId].tap()

        return self
    }

    public func goToThisWeekTab() -> MyStoreScreen {
        return tapTimeframeTab(timeframeId: "period-data-thisWeek-tab")
    }

    public func goToThisMonthTab() -> MyStoreScreen {
        return tapTimeframeTab(timeframeId: "period-data-thisMonth-tab")
    }

    public func goToThisYearTab() -> MyStoreScreen {
        return tapTimeframeTab(timeframeId: "period-data-thisYear-tab")
    }

    func verifyStatsForTimeframeLoaded(timeframe: String) -> MyStoreScreen {
        let textPredicate = NSPredicate(format: "label MATCHES %@", "Store revenue chart \(timeframe)")
        XCTAssertTrue(app.images.containing(textPredicate).element.exists, "\(timeframe) chart not displayed")

        return self
    }

    public func verifyTodayStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "Today")
    }

    public func verifyThisWeekStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "This Week")
    }

    public func verifyThisMonthStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "This Month")
    }

    @discardableResult
    public func verifyThisYearStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "This Year")
    }
}
