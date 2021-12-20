import ScreenObject
import XCTest

public final class TabNavComponent: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable next opening_brace
                { $0.tabBars.firstMatch.buttons["tab-bar-my-store-item"] },
                { $0.tabBars.firstMatch.buttons["tab-bar-orders-item"] },
                { $0.tabBars.firstMatch.buttons["tab-bar-products-item"] },
                { $0.tabBars.firstMatch.buttons["tab-bar-reviews-item"] }
                // swiftlint:enable next opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    func gotoMyStoreScreen() throws -> MyStoreScreen {
        // Avoid transitioning if it is already on screen
        if !MyStoreScreen.isVisible {
            app.tabBars.firstMatch.buttons["tab-bar-my-store-item"].tap()
        }
        return try MyStoreScreen()
    }

    @discardableResult
    public func gotoOrdersScreen() throws -> OrdersScreen {
        // Avoid transitioning if it is already on screen
        guard let orderScreen = try? OrdersScreen(), orderScreen.isLoaded else {
            app.tabBars.firstMatch.buttons["tab-bar-orders-item"].tap()
            return try OrdersScreen()
        }

        return orderScreen
    }

    @discardableResult
    public func gotoProductsScreen() throws -> ProductsScreen {
        if !ProductsScreen.isVisible {
            app.tabBars.firstMatch.buttons["tab-bar-products-item"].tap()
        }

        return try ProductsScreen()
    }

    @discardableResult
    public func gotoReviewsScreen() throws -> ReviewsScreen {
        if !ReviewsScreen.isVisible {
            app.tabBars.firstMatch.buttons["tab-bar-reviews-item"].tap()
        }

        return try ReviewsScreen()
    }

    static func isLoaded() -> Bool {
        (try? TabNavComponent().isLoaded) ?? false
    }

    // TODO: This paradigm is used enough around the test suits that it would be worth extracting to `ScreenObject`.
   static func isVisible() -> Bool {
        guard let tabNavComponent = try? TabNavComponent() else { return false }
        return tabNavComponent.isLoaded && tabNavComponent.expectedElement.isHittable
    }
}
