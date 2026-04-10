import ScreenObject
import XCTest

public final class PeriodStatsTable: ScreenObject {

    private let todayTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-today-tab"]
    }

    private let thisWeekTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-thisWeek-tab"]
    }

    private let thisMonthTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-thisMonth-tab"]
    }

    private let thisYearTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-thisYear-tab"]
    }

    private var todayTab: XCUIElement { todayTabGetter(app) }
    private var thisWeekTab: XCUIElement { thisWeekTabGetter(app) }
    private var thisMonthTab: XCUIElement { thisMonthTabGetter(app) }
    private var thisYearTab: XCUIElement { thisYearTabGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [todayTabGetter, thisWeekTabGetter, thisYearTabGetter],
            app: app
        )
    }

    @discardableResult
    func switchToDaysTab() -> Self {
        todayTab.tap()
        return self
    }

    @discardableResult
    func switchToWeeksTab() -> Self {
        thisWeekTab.tap()
        return self
    }

    @discardableResult
    public func switchToMonthsTab() -> Self {
        thisMonthTab.tap()
        return self
    }

    @discardableResult
    public func switchToYearsTab() -> Self {
        thisYearTab.tap()
        return self
    }
}
