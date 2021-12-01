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

    // TODO: There's only one usage of this and it can be replaced with a screen instantiation
    static var isVisible: Bool {
        (try? OrdersScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                searchButtonGetter,
                filterButtonGetter
            ],
            app: app
        )
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.searchButton].exists
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
