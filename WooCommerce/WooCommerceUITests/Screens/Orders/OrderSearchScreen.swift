import Foundation
import XCTest

final class OrderSearchScreen: BaseScreen {

    struct ElementStringIDs {
        static let searchField = "order-search-screen-search-field"
        static let cancelButton = "order-search-screen-cancel-button"
    }

    private let searchField: XCUIElement
    private let cancelButton: XCUIElement

    static var isVisible: Bool {
        let cancelButton = XCUIApplication().buttons[ElementStringIDs.cancelButton]
        return cancelButton.exists && cancelButton.isHittable
    }

    init() {
        searchField = XCUIApplication().otherElements[ElementStringIDs.searchField]
        cancelButton = XCUIApplication().buttons[ElementStringIDs.cancelButton]
        super.init(element: cancelButton)

        XCTAssert(searchField.waitForExistence(timeout: 3))
        XCTAssert(cancelButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func cancel() -> OrdersScreen {
        cancelButton.tap()
        return OrdersScreen()
    }
}
