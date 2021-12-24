import ScreenObject
import XCTest

// This screen is currently unused. Given the purpose of UITestsFoundation is to provide developers
// with an easy to use API to write tests, I'm going to keep the screen in the framework anyway, so
// it'll be already available if someone needs to work with it or on it in the future.
class BetaFeaturesScreen: ScreenObject {

    // `expectedElement` is a `ScreenObject` utility to get the first element from the
    // `expectedElementGetters` list.
    private var enableProductsButton: XCUIElement { expectedElement }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.cells["beta-features-products-cell"] } ],
            app: app,
            waitTimeout: 7
        )
    }

    @discardableResult
    func enableProducts() -> Self {
        if enableProductsButton.switches.firstMatch.value as? String == "0" {
            enableProductsButton.tap()
        }

        return self
    }

    @discardableResult
    func goBackToSettingsScreen() throws -> SettingsScreen {
        navBackButton.tap()
        return try SettingsScreen()
    }
}
