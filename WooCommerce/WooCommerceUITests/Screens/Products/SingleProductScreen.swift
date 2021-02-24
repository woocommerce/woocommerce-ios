import Foundation
import XCTest

class SingleProductScreen: BaseScreen {

    struct ElementStringIDs {
        static let editProductMenuButton = "edit-product-more-options-button"
    }

    private let editProductMenuButton = XCUIApplication().buttons[ElementStringIDs.editProductMenuButton]

    static var isVisible: Bool {
        let updateButton = XCUIApplication().buttons[ElementStringIDs.editProductMenuButton]
        return updateButton.exists && updateButton.isHittable
    }

    init() {
        super.init(element: editProductMenuButton)
        XCTAssert(editProductMenuButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func goBackToProductList() -> ProductsScreen {
        navBackButton.tap()
        return ProductsScreen()
    }
}
