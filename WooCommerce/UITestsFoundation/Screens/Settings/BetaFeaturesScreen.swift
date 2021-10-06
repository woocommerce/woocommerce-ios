import XCTest

class BetaFeaturesScreen: BaseScreen {

    struct ElementStringIDs {
        static let enableProductsButton = "beta-features-products-cell"
    }

    private let enableProductsButton = XCUIApplication().cells[ElementStringIDs.enableProductsButton]

    init() {
        super.init(element: enableProductsButton)
        XCTAssert(enableProductsButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func enableProducts() -> Self {
        if enableProductsButton.switches.firstMatch.value as? String == "0" {
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
