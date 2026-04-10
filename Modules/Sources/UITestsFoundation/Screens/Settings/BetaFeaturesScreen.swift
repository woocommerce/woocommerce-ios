import ScreenObject
import XCTest

// This screen is currently unused. Given the purpose of UITestsFoundation is to provide developers
// with an easy to use API to write tests, I'm going to keep the screen in the framework anyway, so
// it'll be already available if someone needs to work with it or on it in the future.
public class BetaFeaturesScreen: ScreenObject {

    private let orderCreationGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["beta-features-order-order-creation-cell"]
    }

    /// Table Cell for Order Creation experimental feature
    ///
    private var orderCreation: XCUIElement { orderCreationGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                orderCreationGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func enableOrderCreation() -> Self {
        enableBetaFeature(orderCreation)
        return self
    }

    @discardableResult
    public func goBackToSettingsScreen() throws -> SettingsScreen {
        navBackButton.tap()
        return try SettingsScreen()
    }
}

private extension BetaFeaturesScreen {
    /// Enables the beta feature in the provided cell on the Beta Features screen.
    ///
    func enableBetaFeature(_ cell: XCUIElement) {
        if cell.switches.firstMatch.value as? String == "0" {
            cell.tap()
        }
    }
}
