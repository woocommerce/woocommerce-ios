import ScreenObject
import XCTest

/// This screen is used in both Order Create and Edit flows to reflect that these are unified in the app codebase
///
public final class UnifiedOrderScreen: ScreenObject {

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-create-button"]
    }

    private let recalculateButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-recalculate-button"]
    }

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-cancel-button"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["edit-order-done-button"]
    }

    private let orderStatusEditButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-status-section-edit-button"]
    }

    private let addProductButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-add-product-button"]
    }

    private let addCustomAmountButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["new-order-add-custom-amount-button"]
    }

    private let addCustomerDetailsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Add Customer Details"]
    }

    private let addShippingButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-shipping-button"]
    }

    private let addNoteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-customer-note-button"]
    }

    private let fixedAmountButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["custom-amount-fixed-button"]
    }

    private let percentageOfTotalButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["custom-amount-percentage-button"]
    }

    private let feedbackBannerCloseButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["feedback-banner-popover-close-button"]
    }

    private var createButton: XCUIElement { createButtonGetter(app) }

    private var recalculateButton: XCUIElement { recalculateButtonGetter(app) }

    /// Cancel button in the Navigation bar.
    ///
    private var cancelButton: XCUIElement { cancelButtonGetter(app) }

    /// Done button in the Navigation bar.
    ///
    private var doneButton: XCUIElement { doneButtonGetter(app) }

    /// Edit button in the Order Status section.
    ///
    private var orderStatusEditButton: XCUIElement { orderStatusEditButtonGetter(app) }

    /// Add Product button in Product section.
    ///
    private var addProductButton: XCUIElement { addProductButtonGetter(app) }

    /// Add Custom Amount button in Product section.
    ///
    private var addCustomAmountButton: XCUIElement { addCustomAmountButtonGetter(app) }

    /// Add Customer Details button in the Customer Details section.
    ///
    private var addCustomerDetailsButton: XCUIElement { addCustomerDetailsButtonGetter(app) }

    /// Add Shipping button in the Payment section.
    ///
    private var addShippingButton: XCUIElement { addShippingButtonGetter(app) }

    /// Add Note button in the Customer Note section.
    ///
    private var addNoteButton: XCUIElement { addNoteButtonGetter(app) }

    /// Fixed Amount in Custom Amount sheet.
    ///
    private var fixedAmountButton: XCUIElement { fixedAmountButtonGetter(app) }

    /// Percentage of Order Total Button in Custom Amount ssheet.
    ///
    private var percentageOfTotalButton: XCUIElement { percentageOfTotalButtonGetter(app) }

    /// Close button for Feedback Banner popover.
    ///
    private var feedbackBannerCloseButton: XCUIElement { feedbackBannerCloseButtonGetter(app) }

    public enum Flow {
        case creation
        case editing
    }

    /// Since the screen is unified for creation and editing, pass a parameter to use the correct flow
    /// - Parameter flow: order flow, default is `creation`.
    ///
    public init(app: XCUIApplication = XCUIApplication(), flow: Flow = .creation) throws {
        switch flow {
        case .creation:
            try super.init(
                expectedElementGetters: [ createButtonGetter ],
                app: app
            )
        case .editing:
            try super.init(
                expectedElementGetters: [ doneButtonGetter ],
                app: app
            )
        }
    }

// MARK: - Order Creation Navigation helpers

    /// Opens the Order Status screen (to set a new order status).
    /// - Returns: Order Status screen object.
    private func openOrderStatusScreen() throws -> OrderStatusScreen {
        orderStatusEditButton.tap()
        return try OrderStatusScreen()
    }

    /// Opens the Add Product screen (to add a new product).
    /// - Returns: Add Product screen object.
    private func openAddProductScreen() throws -> AddProductScreen {
        // on iPad, it will already be showing on the left of the side-by side view, and there's no addProductButton
        if UIDevice.current.userInterfaceIdiom == .phone {
            addProductButton.tap()
        }
        return try AddProductScreen()
    }

    /// Opens the Customer Details screen.
    /// - Returns: Customer Details screen object.
    public func openCustomerDetailsScreen() throws -> AddCustomerDetailsScreen {
        // Swipe up to get the addCustomerDetailsButton in view.
        // There's no condition for this because somehow button.exists, button.isHittable and button.isEnabled
        // all returns true even when the button is not fully in view
        app.swipeUp()
        addCustomerDetailsButton.tap()
        return try AddCustomerDetailsScreen()
    }

    /// Opens the Add Shipping screen.
    /// - Returns: Add Shipping screen object.
    public func openAddShippingScreen() throws -> AddShippingScreen {
        addShippingButton.tap()
        return try AddShippingScreen()
    }

    /// Opens the Add Custom Amount screen.
    /// - Returns: Add Custom Amount screen object.
    public func openAddCustomAmountScreen() throws -> AddCustomAmountScreen {
        addCustomAmountButton.tap()
        selectFixedAmount()
        return try AddCustomAmountScreen()
    }

    private func selectFixedAmount() {
        fixedAmountButton.waitAndTap()
    }

    /// Opens the Customer Note screen.
    /// - Returns: Customer Note screen object.
    public func openCustomerNoteScreen() throws -> CustomerNoteScreen {
        /// The `scrollintoView` function doesn’t perform any scrolling on the iPad, because `isFullyVisibleOnScreen`
        /// is returning true, even when the note button is hidden (just) below the expandable totals drawer.
        /// Unfortunately, the button can't be tapped in this instance.
        app.scrollViews["order-form-scroll-view"].swipeUp()

        addNoteButton.scrollIntoView()
        addNoteButton.tap()
        return try CustomerNoteScreen()
    }

    /// Closes the feedback banner popover, if needed.
    /// - Returns: Unified Order screen object.
    @discardableResult
    func closeFeedbackBannerPopoverIfNeeded() -> UnifiedOrderScreen {
        if feedbackBannerCloseButton.exists {
            feedbackBannerCloseButton.tap()
        }
        return self
    }

// MARK: - High-level Order Creation actions

    /// Creates a remote order with all of the entered order data.
    /// - Returns: Single Order Detail screen object.
    public func createOrder() throws -> SingleOrderScreen {
        createButton.tap()
        return try SingleOrderScreen()
    }

    public func recalculateTotalIfRequired() {
        if recalculateButton.exists {
            recalculateButton.tap()
        }
    }

    /// Changes the new order status to the second status in the Order Status list.
    /// - Returns: Unified Order screen object.
    public func editOrderStatus() throws -> UnifiedOrderScreen {
      return try openOrderStatusScreen()
            .tapOrderStatus(atIndex: 1)
    }

    /// Tap the first product from the addProductScreen
    /// - Returns: Unified Order screen object.
    public func addProduct(byName name: String) throws -> UnifiedOrderScreen {
        try openAddProductScreen()
            .tapProduct(byName: name)
        recalculateTotalIfRequired()
        return try UnifiedOrderScreen()
    }

    /// Tap the first product from the addProductScreen
    /// - Returns: Unified Order screen object.
    public func addProducts(numberOfProductsToAdd numberOfProducts: Int) throws -> UnifiedOrderScreen {
        return try openAddProductScreen()
            .tapMultipleProducts(numberOfProductsToAdd: numberOfProducts)
    }

    /// Adds minimal customer details on the Customer Details screen
    /// - Returns: Unified Order screen object.
    public func addCustomerDetails(name: String) throws -> UnifiedOrderScreen {
        return try openCustomerDetailsScreen()
            .tapAddCustomerDetailsPlusButton()
            .enterCustomerDetails(name: name)
    }

    /// Adds shipping on the Add Shipping screen.
    /// - Parameters:
    ///   - amount: Amount (in the store currency) to add for shipping.
    ///   - name: Name of the shipping method (e.g. "Free Shipping" or "Flat Rate").
    /// - Returns: Unified Order screen object.
    public func addShipping(amount: String, name: String) throws -> UnifiedOrderScreen {
        return try openAddShippingScreen()
            .enterShippingAmount(amount)
            .enterShippingName(name)
            .confirmShippingDetails()
            .closeFeedbackBannerPopoverIfNeeded()
    }

    /// Adds a fee on the Custom Amount screen.
    /// - Parameters:
    ///   - amount: Amount (in the store currency) to add as a custom amount.
    /// - Returns: Unified Order screen object.
    public func addCustomAmount(amount: String) throws -> UnifiedOrderScreen {
        return try openAddCustomAmountScreen()
            .enterCustomAmount(amount: amount)
            .addCustomAmountTap()
    }

    /// Adds a note on the Customer Note screen.
    /// - Parameter text: Text to enter as the customer note.
    /// - Returns: Unified Order screen object.
    public func addCustomerNote(_ text: String) throws -> UnifiedOrderScreen {
        // Add Customer note button is the lowermost element on the screen
        // Adding a swipeup for better stability on iPad.
        app.swipeUp()
        return try openCustomerNoteScreen()
            .enterNote(text)
            .confirmNote()
    }

    /// Cancels Order Creation process
    /// - Returns: Orders Screen object.
    public func cancelOrderCreation() throws -> OrdersScreen {
        cancelButton.tap()
        return try OrdersScreen()
    }

    /// Checks the screen for existence of the title with correct order number.
    /// - Parameter orderNumber: Existing order number to check.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func checkForExistingOrderTitle(byOrderNumber orderNumber: String) throws -> UnifiedOrderScreen {
        let orderNumberPredicate = NSPredicate(format: "label MATCHES %@", "Order #\(orderNumber)")
        XCTAssertTrue(app.staticTexts.containing(orderNumberPredicate).element.exists)

        return self
    }

    /// Checks the screen for existence of all products, checking each name.
    /// - Parameter productNames: Array of product names to check.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func checkForExistingProducts(byName productNames: [String]) throws -> UnifiedOrderScreen {
        for productName in productNames {
            let productNamePredicate = NSPredicate(format: "label MATCHES %@", productName)
            XCTAssertTrue(app.staticTexts.containing(productNamePredicate).element.exists)
        }

        return self
    }

    /// Finishes Order Editing process
    /// - Returns: Single Order Screen object.
    public func closeEditingFlow() throws -> SingleOrderScreen {
        doneButton.tap()

        return try SingleOrderScreen()
    }
}
