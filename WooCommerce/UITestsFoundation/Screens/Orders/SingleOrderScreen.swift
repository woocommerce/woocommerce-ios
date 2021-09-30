import ScreenObject
import XCTest

public final class SingleOrderScreen: ScreenObject {

    let tabBar = TabNavComponent()

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["summary-table-view-cell-title-label"] } ],
            app: app
        )
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
