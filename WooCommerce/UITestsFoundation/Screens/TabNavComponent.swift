import ScreenObject
import XCTest

public final class TabNavComponent: ScreenObject {

    private let myStoreTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-my-store-item"]
    }

    private let ordersTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-orders-item"]
    }

    private let reviewsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-reviews-item"]
    }

    private let productsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-products-item"]
    }

    private var myStoreTabButton: XCUIElement { myStoreTabButtonGetter(app) }
    private var ordersTabButton: XCUIElement { ordersTabButtonGetter(app) }
    private var reviewsTabButton: XCUIElement { reviewsTabButtonGetter(app) }
    var productsTabButton: XCUIElement { productsTabButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                myStoreTabButtonGetter,
                ordersTabButtonGetter,
                reviewsTabButtonGetter,
                productsTabButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    func gotoMyStoreScreen() throws -> MyStoreScreen {
        // Avoid transitioning if it is already on screen
        if !MyStoreScreen.isVisible {
            myStoreTabButton.tap()
        }
        return try MyStoreScreen()
    }

    @discardableResult
    public func gotoOrdersScreen() throws -> OrdersScreen {
        // Avoid transitioning if it is already on screen
        if !OrdersScreen.isVisible {
            ordersTabButton.tap()
        }

        return try OrdersScreen()
    }

    @discardableResult
    public func gotoProductsScreen() throws -> ProductsScreen {
        if !ProductsScreen.isVisible {
            productsTabButton.tap()
        }

        return try ProductsScreen()
    }

    @discardableResult
    public func gotoReviewsScreen() throws -> ReviewsScreen {
        if !ReviewsScreen.isVisible {
            reviewsTabButton.tap()
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
