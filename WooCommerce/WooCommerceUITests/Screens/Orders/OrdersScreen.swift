import Foundation
import XCTest

final class OrdersScreen: BaseScreen {

    struct ElementStringIDs {
        static let searchButton = "order-search-button"
        static let filterButton = "order-filter-button"
    }

    let tabBar = TabNavComponent()
    private let searchButton: XCUIElement
    private let filterButton: XCUIElement

    static var isVisible: Bool {
        let searchButton = XCUIApplication().buttons[ElementStringIDs.searchButton]
        return searchButton.exists && searchButton.isHittable
    }

    init() {
        searchButton = XCUIApplication().buttons[ElementStringIDs.searchButton]
        filterButton = XCUIApplication().buttons[ElementStringIDs.filterButton]

        super.init(element: searchButton)
    }

    @discardableResult
    func selectOrder(atIndex index: Int) -> SingleOrderScreen {
        XCUIApplication().tables.cells.element(boundBy: index).tap()
        return SingleOrderScreen()
    }

    @discardableResult
    func openSearchPane() -> OrderSearchScreen {
        searchButton.tap()
        return OrderSearchScreen()
    }
}
