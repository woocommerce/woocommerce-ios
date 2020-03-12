import Foundation
import XCTest

class SingleProductScreen: BaseScreen {

    struct ElementStringIDs {
        static let updateButton = "single-product-update-button"
    }

    private let updateButton = XCUIApplication().buttons[ElementStringIDs.updateButton]

    static var isVisible: Bool {
        let updateButton = XCUIApplication().buttons[ElementStringIDs.updateButton]
        return updateButton.exists && updateButton.isHittable
    }

    init() {
        super.init(element: updateButton)
        XCTAssert(updateButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func goBackToProductList() -> ProductsScreen {
        navBackButton.tap()
        return ProductsScreen()
    }
}
