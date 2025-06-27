import ScreenObject
import XCTest

public final class AddCustomerDetailsScreen: ScreenObject {
    private let addCustomerDetailsNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Add customer details"]
    }

    private let addCustomerDetailsPlusButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-customer-details-plus-button"]
    }

    private var addCustomerDetailsPlusButton: XCUIElement { addCustomerDetailsPlusButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ addCustomerDetailsNavigationBarGetter, addCustomerDetailsPlusButtonGetter ],
            app: app
        )
    }

    public func tapAddCustomerDetailsPlusButton() throws -> CustomerDetailsScreen {
        addCustomerDetailsPlusButton.tap()
        return try CustomerDetailsScreen()
    }
}
