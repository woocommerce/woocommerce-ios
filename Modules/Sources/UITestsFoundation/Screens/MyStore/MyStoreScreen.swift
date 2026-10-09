import ScreenObject
import XCTest

public final class MyStoreScreen: ScreenObject {

    static var isVisible: Bool {
        (try? MyStoreScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["my-store-title"] }],
            app: app,
            waitTimeout: 60
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
        let element = app.staticTexts["performance-\(timeframe)"]
        let elementExists = element.waitForExistence(timeout: 30)

        XCTAssertTrue(elementExists, "\(timeframe) chart not displayed")

        return self
    }

    public func verifyTodayStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "time-range-today")
    }

    public func verifyThisWeekStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "time-range-this-week")
    }

    public func verifyThisMonthStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "time-range-this-month")
    }

    @discardableResult
    public func verifyThisYearStatsLoaded() -> MyStoreScreen {
        return verifyStatsForTimeframeLoaded(timeframe: "time-range-this-year")
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
