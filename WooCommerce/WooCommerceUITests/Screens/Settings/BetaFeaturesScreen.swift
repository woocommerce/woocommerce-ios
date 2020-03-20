import Foundation
import XCTest

class BetaFeaturesScreen: BaseScreen {

    struct ElementStringIDs {
        static let enableProductsButton = "beta-features-products-cell"
    }

    private let enableProductsButton = XCUIApplication().cells[ElementStringIDs.enableProductsButton]

    static var isVisible: Bool {
        let enableProductsButton = XCUIApplication().buttons[ElementStringIDs.enableProductsButton]
        return enableProductsButton.exists && enableProductsButton.isHittable
    }

    init() {
        super.init(element: enableProductsButton)
        XCTAssert(enableProductsButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func enableProducts() -> Self {
        if enableProductsButton.switches.firstMatch.stringValue == "0" {
            enableProductsButton.tap()
        }

        return self
    }

    @discardableResult
    func goBackToSettingsScreen() -> SettingsScreen {
        navBackButton.tap()
        return SettingsScreen()
    }
}
