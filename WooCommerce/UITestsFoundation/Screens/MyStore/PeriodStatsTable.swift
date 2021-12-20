import ScreenObject
import XCTest

public final class PeriodStatsTable: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.cells["period-data-today-tab"] },
                { $0.cells["period-data-thisWeek-tab"] },
                { $0.cells["period-data-thisYear-tab"] }
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    func switchToDaysTab() -> Self {
        app.cells["period-data-today-tab"].tap()
        return self
    }

    @discardableResult
       func switchToWeeksTab() -> Self {
           app.cells["period-data-thisWeek-tab"].tap()
           return self
       }

    @discardableResult
    public func switchToYearsTab() -> Self {
        app.cells["period-data-thisYear-tab"].tap()
        return self
    }
}
