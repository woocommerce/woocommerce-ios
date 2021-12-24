import ScreenObject
import XCTest

private struct ElementStringIDs {
    static let searchButton = "order-search-button"
    static let filterButton = "Filter"
}

public final class OrdersScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

    private let searchButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.searchButton]
    }

    private let filterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.filterButton]
    }

    private var searchButton: XCUIElement { searchButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                searchButtonGetter,
                filterButtonGetter
            ],
            app: app,
            waitTimeout: 7
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
