import Foundation
import XCTest

class OrderSearchScreen: BaseScreen {

    struct ElementStringIDs {
        static let searchField = "order-search-screen-search-field"
        static let cancelButton = "order-search-screen-cancel-button"
    }

    let searchField: XCUIElement
    let cancelButton: XCUIElement

    static var isVisible: Bool {
        let cancelButton = XCUIApplication().buttons[ElementStringIDs.cancelButton]
        return cancelButton.exists && cancelButton.isHittable
    }

    init() {

//        if #available(iOS 13.0, *) {
//            searchField = XCUIApplication().searchFields[ElementStringIDs.searchField]
//        }
//        else {
            searchField = XCUIApplication().otherElements[ElementStringIDs.searchField]
//        }

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
