import ScreenObject
import XCTest

public final class PeriodStatsTable: ScreenObject {

    private let daysTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-today-tab"]
    }

    private let weeksTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-thisWeek-tab"]
    }

    private let yearsTabGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["period-data-thisYear-tab"]
    }

    private var daysTab: XCUIElement { daysTabGetter(app) }
    private var weeksTab: XCUIElement { weeksTabGetter(app) }
    private var yearsTab: XCUIElement { yearsTabGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [daysTabGetter, weeksTabGetter, yearsTabGetter],
            app: app,
            waitTimeout: 7
        )
    }

    @discardableResult
    func switchToDaysTab() -> Self {
        daysTab.tap()
        return self
    }

    @discardableResult
       func switchToWeeksTab() -> Self {
           weeksTab.tap()
           return self
       }

    @discardableResult
    public func switchToYearsTab() -> Self {
        yearsTab.tap()
        return self
    }
}
