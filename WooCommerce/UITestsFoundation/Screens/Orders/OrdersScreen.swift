import ScreenObject
import XCTest

public final class OrdersScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.buttons["order-search-button"] },
                { $0.buttons["Filter"] }
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func selectOrder(atIndex index: Int) throws -> SingleOrderScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleOrderScreen()
    }

    @discardableResult
    public func openSearchPane() throws -> OrderSearchScreen {
        app.buttons["order-search-button"].tap()
        return try OrderSearchScreen()
    }
}
