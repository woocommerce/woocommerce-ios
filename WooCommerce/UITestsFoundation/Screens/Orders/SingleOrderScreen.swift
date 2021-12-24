import ScreenObject
import XCTest

public final class SingleOrderScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    let tabBar = try! TabNavComponent()

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.staticTexts["summary-table-view-cell-title-label"] } ],
            app: app,
            waitTimeout: 7
        )
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
