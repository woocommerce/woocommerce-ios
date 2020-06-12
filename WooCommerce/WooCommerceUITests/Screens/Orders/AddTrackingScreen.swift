import Foundation
import XCTest

final class AddTrackingScreen: BaseScreen {

    struct ElementStringIDs {
        static let addButton = "add-tracking-add-button"
        static let dismissButton = "add-tracking-dismiss-button"
        static let shippingCarrierField = "add-tracking-shipping-carrier-cell"
        static let trackingNumberField = "add-tracking-enter-tracking-number-field"
        static let shippingDateField = "add-tracking-date-shipped-cell"
    }

    private let addButton: XCUIElement
    private let dismissButton: XCUIElement
    private let shippingCarrierField: XCUIElement
    private let trackingNumberField: XCUIElement
    private let shippingDateField: XCUIElement

    static var isVisible: Bool {
        let shippingCarrierField = XCUIApplication().buttons[ElementStringIDs.shippingCarrierField]
        return shippingCarrierField.exists && shippingCarrierField.isHittable
    }

    init() {
        addButton = XCUIApplication().navigationBars.buttons[ElementStringIDs.addButton]
        dismissButton = XCUIApplication().navigationBars.buttons[ElementStringIDs.dismissButton]
        shippingCarrierField = XCUIApplication().cells[ElementStringIDs.shippingCarrierField]
        trackingNumberField = XCUIApplication().textFields[ElementStringIDs.trackingNumberField]
        shippingDateField = XCUIApplication().cells[ElementStringIDs.shippingDateField]
        super.init(element: shippingDateField)
    }

    // This method doesn't return another screen object because you return to where you started.
    // This screen can be accessed from the SingleOrderScreen and the FulfillOrderScreen.
    func addTrackingInfo(carrier: String, trackingNumber: String) {
        XCTAssert(!addButton.isEnabled, "Add button should not be enabled before adding tracking info")
        selectCarrier().selectShippingCarrier(withName: carrier)
        XCTAssert(!addButton.isEnabled, "Add button should not be enabled without complete tracking info")
        addTrackingNumber(number: trackingNumber)
        XCTAssert(addButton.isEnabled, "Add button should be enabled after adding tracking info")
        canSetDateShipped()
        addButton.tap()
    }

    override func pop() {
        dismissButton.tap()
    }

    @discardableResult
    private func selectCarrier() -> ShippingCarriersScreen {
        shippingCarrierField.tap()
        return ShippingCarriersScreen()
    }

    private func addTrackingNumber(number: String) {
        trackingNumberField.tap()
        trackingNumberField.typeText(number)
    }

    private func canSetDateShipped() {
        shippingDateField.tap()
        XCTAssert(XCUIApplication().pickerWheels.element(boundBy: 0).isHittable)
        XCTAssert(XCUIApplication().pickerWheels.element(boundBy: 1).isHittable)
        XCTAssert(XCUIApplication().pickerWheels.element(boundBy: 2).isHittable)
    }
}
