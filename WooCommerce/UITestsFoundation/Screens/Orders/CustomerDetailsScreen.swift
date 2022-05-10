import ScreenObject
import XCTest

public final class CustomerDetailsScreen: ScreenObject {

    private let addressToggleGetter: (XCUIApplication) -> XCUIElement = {
        $0.switches["order-creation-customer-details-shipping-address-toggle"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-customer-details-done-button"]
    }

    private let shippingFirstNameFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["secondary-order-address-form"].descendants(matching: .textField)["order-address-form-first-name-field"]
    }

    private let billingFirstNameFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["order-address-form"].descendants(matching: .textField)["order-address-form-first-name-field"]
    }

    private var addressToggle: XCUIElement { addressToggleGetter(app) }

    private var doneButton: XCUIElement { doneButtonGetter(app) }

    private var shippingFirstNameField: XCUIElement { shippingFirstNameFieldGetter(app) }

    private var billingFirstNameField: XCUIElement { billingFirstNameFieldGetter(app) }


    init(app: XCUIApplication = XCUIApplication()) throws {
    //    print(app.otherElements)
    //    print(app.buttons)
   //     print(app.groups)
   //     print(app.otherElements.allElementsBoundByIndex)
        try super.init(
            expectedElementGetters: [ addressToggleGetter ],
            app: app
        )
    }

    /// Updates the order with minimal customer details.
    /// - Returns: New Order screen object.
    @discardableResult
    public func enterCustomerDetails() throws -> NewOrderScreen {
        firstNameField.tap()
        firstNameField.typeText("Mira")
    //    addressToggle.tap()
        //
        //        app.elements[“shipping-form”].textFields[“name-field”].tap
        //        enter some Text
        doneButton.tap()
        //closeButton.tap()
        return try NewOrderScreen()
    }
}
