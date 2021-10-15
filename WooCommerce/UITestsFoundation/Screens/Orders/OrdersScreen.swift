import ScreenObject
import XCTest

public final class OrdersScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

    private let searchButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-search-button"]
    }

    private var searchButton: XCUIElement { searchButtonGetter(app) }

    // TODO: There's only one usage of this and it can be replaced with a screen instantiation
    static var isVisible: Bool {
        (try? OrdersScreen().isLoaded) ?? false
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                searchButtonGetter,
                // swiftlint:disable:next opening_braces
                { $0.buttons["order-filter-button"] }
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
        searchButton.tap()
        return try OrderSearchScreen()
    }
}
