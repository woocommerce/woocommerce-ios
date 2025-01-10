import ScreenObject
import XCTest

public final class MyStoreScreen: ScreenObject {

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

    func tapTimeRangeOption(id: String) -> MyStoreScreen {
        app.buttons["performance-time-range-menu"].tap()
        app.buttons[id].tap()

        return self
    }

    @discardableResult
    public func goToThisWeekTab() -> MyStoreScreen {
        return tapTimeRangeOption(id: "time-range-this-week")
    }

    @discardableResult
    public func goToThisMonthTab() -> MyStoreScreen {
        return tapTimeRangeOption(id: "time-range-this-month")
    }

    @discardableResult
    public func goToThisYearTab() -> MyStoreScreen {
        return tapTimeRangeOption(id: "time-range-this-year")
    }

    func verifyStatsForTimeframeLoaded(timeframe: String) -> MyStoreScreen {
        let textPredicate = NSPredicate(format: "label MATCHES %@", "\(timeframe)")
        XCTAssertTrue(app.staticTexts.containing(textPredicate).element.exists, "\(timeframe) chart not displayed")

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

    public func getRevenueValue() -> String {
        return app.staticTexts["revenue-value"].label
    }

    public func tapChart() {
        app.otherElements["store-stats-chart"].tap()
    }

    public func verifyRevenueUpdated(originalRevenue: String, updatedRevenue: String) {
        XCTAssertNotEqual(originalRevenue, updatedRevenue, "Revenue is not updated!")
    }
}
