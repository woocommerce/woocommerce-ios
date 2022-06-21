import ScreenObject
import XCTest

public final class NewOrderScreen: ScreenObject {

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-create-button"]
    }

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-cancel-button"]
    }

    private let orderStatusEditButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-status-section-edit-button"]
    }

    private let addProductButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-add-product-button"]
    }

    private let addCustomerDetailsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Add Customer Details"]
    }

    private let addShippingButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-shipping-button"]
    }

    private var createButton: XCUIElement { createButtonGetter(app) }

    /// Cancel button in the Navigation bar.
    ///
    private var cancelButton: XCUIElement { cancelButtonGetter(app) }

    /// Edit button in the Order Status section.
    ///
    private var orderStatusEditButton: XCUIElement { orderStatusEditButtonGetter(app) }

    /// Add Product button in Product section.
    ///
    private var addProductButton: XCUIElement { addProductButtonGetter(app) }

    /// Add Customer Details button in the Customer Details section.
    ///
    private var addCustomerDetailsButton: XCUIElement { addCustomerDetailsButtonGetter(app) }

    /// Add Shipping button in the Payment section.
    ///
    private var addShippingButton: XCUIElement { addShippingButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ createButtonGetter ],
            app: app
        )
    }

// MARK: - Order Creation Navigation helpers

    /// Opens the Order Status screen (to set a new order status).
    /// - Returns: Order Status screen object.
    @discardableResult
    private func openOrderStatusScreen() throws -> OrderStatusScreen {
        orderStatusEditButton.tap()
        return try OrderStatusScreen()
    }

    /// Opens the Add Product screen (to add a new product).
    /// - Returns: Add Product screen object.
    @discardableResult
    private func openAddProductScreen() throws -> AddProductScreen {
        addProductButton.tap()
        return try AddProductScreen()
    }

    /// Opens the Customer Details screen.
    /// - Returns: Customer Details screen object.
    @discardableResult
    public func openCustomerDetailsScreen() throws -> CustomerDetailsScreen {
        addCustomerDetailsButton.tap()
        return try CustomerDetailsScreen()
    }

    /// Opens the Add Shipping screen.
    /// - Returns: Add Shipping screen object.
    @discardableResult
    public func openAddShippingScreen() throws -> AddShippingScreen {
        addShippingButton.tap()
        return try AddShippingScreen()
    }

// MARK: - High-level Order Creation actions

    /// Creates a remote order with all of the entered order data.
    /// - Returns: Single Order Detail screen object.
    @discardableResult
    public func createOrder() throws -> SingleOrderScreen {
        createButton.tap()
        return try SingleOrderScreen()
    }

    /// Changes the new order status to the second status in the Order Status list.
    /// - Returns: New Order screen object.
    @discardableResult
    public func editOrderStatus() throws -> NewOrderScreen {
      return try openOrderStatusScreen()
            .selectOrderStatus(atIndex: 1)
    }

    /// Select the first product from the addProductScreen
    /// - Returns: New Order screen object.
    @discardableResult
    public func addProduct(byName name: String) throws -> NewOrderScreen {
        return try openAddProductScreen()
            .selectProduct(byName: name)
    }

    /// Adds minimal customer details on the Customer Details screen
    /// - Returns: New Order screen object.
    public func addCustomerDetails(name: String) throws -> NewOrderScreen {
        return try openCustomerDetailsScreen()
            .enterCustomerDetails(name: name)
    }

    /// Adds shipping on the Add Shipping screen.
    /// - Parameters:
    ///   - amount: Amount (in the store currency) to add for shipping.
    ///   - name: Name of the shipping method (e.g. "Free Shipping" or "Flat Rate").
    /// - Returns: New Order screen object.
    public func addShipping(amount: String, name: String) throws -> NewOrderScreen {
        return try openAddShippingScreen()
            .enterShippingAmount(amount)
            .enterShippingName(name)
            .confirmShippingDetails()
    }

    /// Cancels Order Creation process
    /// - Returns: Orders Screen object.
    @discardableResult
    public func cancelOrderCreation() throws -> OrdersScreen {
        cancelButton.tap()
        return try OrdersScreen()
    }
}
