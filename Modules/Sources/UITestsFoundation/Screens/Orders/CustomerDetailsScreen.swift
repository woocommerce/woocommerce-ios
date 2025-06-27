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
        try super.init(
            expectedElementGetters: [ addressToggleGetter ],
            app: app
        )
    }

    /// Updates the order with minimal customer details.
    /// - Returns: Unified Order screen object.
    @discardableResult
    public func enterCustomerDetails(name: String) throws -> UnifiedOrderScreen {
        billingFirstNameField.tap()
        billingFirstNameField.typeText(name)
        addressToggleSet(to: "1")
        shippingFirstNameField.tap()
        shippingFirstNameField.typeText(name)
        doneButton.tap()
        return try UnifiedOrderScreen()
    }

    @discardableResult
    func addressToggleSet(to value: String) -> Bool {
        // If the switch state is not as needed, tap.
        if addressToggle.value as! String != value {
            addressToggle.tap()
        }

        // If the switch state is still not as needed, tap its inner switch, if it's hittable.
        // See https://github.com/woocommerce/woocommerce-ios/pull/9629 for more details.
        if addressToggle.value as! String != value && addressToggle.switches.firstMatch.isHittable {
            addressToggle.switches.firstMatch.tap()
        }

        return addressToggle.value as! String == value
    }

}
