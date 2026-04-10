import ScreenObject
import XCTest

public final class OrderSearchScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.buttons["order-search-screen-cancel-button"] },
                { $0.otherElements["order-search-screen-search-field"] }
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func cancel() throws -> OrdersScreen {
        app.buttons["order-search-screen-cancel-button"].tap()
        return try OrdersScreen()
    }
}
