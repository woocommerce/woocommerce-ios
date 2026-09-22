import ScreenObject
import XCTest
import XCUITestHelpers

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
    private let posTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-pos-item"]
    }
    private let menuTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars.firstMatch.buttons["tab-bar-menu-item"]
    }
    private var myStoreTabButton: XCUIElement { myStoreTabButtonGetter(app) }
    private var ordersTabButton: XCUIElement { ordersTabButtonGetter(app) }
    private var menuTabButton: XCUIElement { menuTabButtonGetter(app) }
    private var productsTabButton: XCUIElement { productsTabButtonGetter(app) }
    private var posTabButton: XCUIElement { posTabButtonGetter(app) }

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
        try selectOrdersTab()
        return try OrdersScreen(app: app)
    }
    @discardableResult
    public func goToProductsScreen() throws -> ProductsScreen {
        productsTabButton.tap()
        return try ProductsScreen()
    }
    public func goToPOSScreen() throws -> POSScreen {
        posTabButton.waitAndTap()
        return try POSScreen(app: app)
    }
    @discardableResult
    public func goToPOSIneligibleScreen() throws -> POSIneligibleScreen {
        posTabButton.waitAndTap()
        return try POSIneligibleScreen(app: app)
    }
    @discardableResult
    public func goToMenuScreen() throws -> MenuScreen {
        menuTabButton.tap()
        return try MenuScreen()
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

private extension TabNavComponent {
    func selectOrdersTab(maxAttempts: Int = 3) throws {
        for _ in 0..<maxAttempts {
            let ordersTabButton = ordersTabButtonGetter(app)
            // XCUIElement is main-actor isolated and UI tests drive it from the main thread.
            let selected = MainActor.assumeIsolated {
                guard ordersTabButton.waitForIsHittable(timeout: 5) else {
                    return false
                }
                ordersTabButton.tap()
                return ordersTabButton.waitFor(predicateString: "isSelected == true", timeout: 2) == .completed
            }
            if selected {
                return
            }
        }

        throw TabNavigationError.ordersTabSelectionTimedOut
    }

    enum TabNavigationError: Error {
        case ordersTabSelectionTimedOut
    }
}
