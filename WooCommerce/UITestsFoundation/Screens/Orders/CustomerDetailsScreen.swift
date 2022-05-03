import ScreenObject
import XCTest
import WooCommerce

public final class CustomerDetailsScreen: ScreenObject {

    private let addressToggleGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-creation-customer-details-shipping-address-toggle"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["customer-details-done-button"]
    }


    private var addressToggle: XCUIElement { addressToggleGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }


    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ addressToggleGetter ],
            app: app
        )
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
        doneButton.tap()
        return try NewOrderScreen()
    }
}
