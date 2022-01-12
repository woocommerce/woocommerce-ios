import ScreenObject
import XCTest

public final class TabNavComponent: ScreenObject {

    private let myStoreTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-my-store-item"]
    }

    private let ordersTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-orders-item"]
    }

    private let productsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-products-item"]
    }

    private let menuTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-menu-item"]
    }

    private let reviewsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-reviews-item"]
    }

    private var myStoreTabButton: XCUIElement { myStoreTabButtonGetter(app) }
    private var ordersTabButton: XCUIElement { ordersTabButtonGetter(app) }
    private var menuTabButton: XCUIElement { menuTabButtonGetter(app) }
    private var reviewsTabButton: XCUIElement { reviewsTabButtonGetter(app) }
    var productsTabButton: XCUIElement { productsTabButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                myStoreTabButtonGetter,
                ordersTabButtonGetter,
                productsTabButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func goToMyStoreScreen() throws -> MyStoreScreen {
        myStoreTabButton.tap()
        return try MyStoreScreen()
    }

    @discardableResult
    public func goToOrdersScreen() throws -> OrdersScreen {
        ordersTabButton.tap()
        return try OrdersScreen()
    }

    @discardableResult
    public func goToProductsScreen() throws -> ProductsScreen {
        productsTabButton.tap()
        return try ProductsScreen()
    }

    @discardableResult
    public func goToMenuScreen() throws -> MenuScreen {
        menuTabButton.tap()
        return try MenuScreen()
    }

    @discardableResult
    public func goToReviewsScreen() throws -> ReviewsScreen {
        reviewsTabButton.tap()
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
