import ScreenObject
import XCTest
import XCUITestHelpers

@MainActor
public final class TabNavComponent: ScreenObject {
    private let myStoreTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["tab-bar-my-store-item"]
    }
    private let ordersTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["tab-bar-orders-item"]
    }
    private let productsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["tab-bar-products-item"]
    }
    private let posTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["tab-bar-pos-item"]
    }
    private let menuTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["tab-bar-menu-item"]
    }
    private var myStoreTabButton: XCUIElement { myStoreTabButtonGetter(app) }
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
        try selectTab(ordersTabButtonGetter, named: "Orders")
        return try OrdersScreen(app: app)
    }
    @discardableResult
    public func goToProductsScreen() throws -> ProductsScreen {
        try selectTab(productsTabButtonGetter, named: "Products")
        return try ProductsScreen(app: app)
    }
    public func goToPOSScreen() throws -> POSScreen {
        tapPOSTab()
        return try POSScreen(app: app)
    }
    @discardableResult
    public func goToPOSIneligibleScreen() throws -> POSIneligibleScreen {
        tapPOSTab()
        return try POSIneligibleScreen(app: app)
    }
    @discardableResult
    public func goToMenuScreen() throws -> MenuScreen {
        try selectTab(menuTabButtonGetter, named: "Menu")
        return try MenuScreen(app: app)
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
    func tapPOSTab() {
        XCTAssertTrue(posTabButton.waitForIsHittable(timeout: 10), "POS tab should be tappable.")
        // XCTest can report the tab as hittable and still synthesize a tap outside the tab bar.
        posTabButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func selectTab(_ tabButtonGetter: (XCUIApplication) -> XCUIElement, named name: String, maxAttempts: Int = 3) throws {
        for _ in 0..<maxAttempts {
            let tabButton = tabButtonGetter(app)
            guard tabButton.waitForIsHittable(timeout: 5) else {
                continue
            }
            tabButton.tap()
            if tabButton.waitFor(predicateString: "isSelected == true", timeout: 2) == .completed {
                return
            }
        }

        throw TabNavigationError.selectionTimedOut(tab: name)
    }

    enum TabNavigationError: Error {
        case selectionTimedOut(tab: String)
    }
}
