import ScreenObject
import XCTest

public final class CustomerDetailsScreen: ScreenObject {

    private let addressToggleGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-creation-customer-details-shipping-address-toggle"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["customer-details-done-button"]
    }

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["close"]
    }

    private var addressToggle: XCUIElement { addressToggleGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    private var closeButton: XCUIElement { closeButtonGetter(app) }


    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ closeButtonGetter ],
            app: app
        )
    }


    /// Changes the new order status to the second status in the Order Status list.
    /// - Returns: New Order screen object.
    @discardableResult
    public func closeCustomerDetailsScreen() throws -> NewOrderScreen {
        closeButton.tap()
        return try NewOrderScreen()
    }

    /// Updates the order with basic customer details.
    /// - Returns: New Order screen object.
    @discardableResult
    public func addCustomerDetails() throws -> NewOrderScreen {
        //        app.elements[“billing-form”].textFields[“name-field”].tap
        //        enter some text
        addressToggle.tap()
        //        app.elements[“billing-form”].textFields[“name-field”].tap
        //        enter some Text
        //doneButton.tap()
        closeButton.tap()
        return try NewOrderScreen()
    }
}
