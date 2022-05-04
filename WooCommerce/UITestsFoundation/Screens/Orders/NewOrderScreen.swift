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
            .confirmSelectedOrderStatus()
    }

    /// Select the first product from the addProductScreen
    /// - Returns: New Order screen object.
    @discardableResult
    public func addProduct(byName name: String) throws -> NewOrderScreen {
        return try openAddProductScreen()
            .selectProduct(byName: name)
    }

    /// Cancels Order Creation process
    /// - Returns: Orders Screen object.
    @discardableResult
    public func cancelOrderCreation() throws -> OrdersScreen {
        cancelButton.tap()
        return try OrdersScreen()
    }

    /// Opens the Customer Details screen.
    /// - Returns: Customer Details screen object.
    @discardableResult
    public func openCustomerDetailsScreen() throws -> CustomerDetailsScreen {
        addCustomerDetailsButton.tap()
        return try CustomerDetailsScreen()
    }

    public func addCustomerDetails() throws -> NewOrderScreen {
        return try openCustomerDetailsScreen()
            .enterCustomerDetails()
    }

    public func checkCustomerDetails() throws -> NewOrderScreen {
        return try openCustomerDetailsScreen()
        .closeCustomerDetailsScreen()
    }
}
