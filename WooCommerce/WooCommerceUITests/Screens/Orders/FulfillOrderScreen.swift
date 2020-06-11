import Foundation
import XCTest

final class FulfillOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let markOrderCompleteButton = "mark-order-complete-button"
        static let addTrackingButton = "fulfill-order-add-tracking-button"
    }

    private let markOrderCompleteButton: XCUIElement
    private let addTrackingButton: XCUIElement

    static var isVisible: Bool {
        let markOrderCompleteButton = XCUIApplication().buttons[ElementStringIDs.markOrderCompleteButton]
        return markOrderCompleteButton.exists && markOrderCompleteButton.isHittable
    }

    init() {
        markOrderCompleteButton = XCUIApplication().buttons[ElementStringIDs.markOrderCompleteButton]
        addTrackingButton = XCUIApplication().cells[ElementStringIDs.addTrackingButton]
        super.init(element: markOrderCompleteButton)
    }

    func canAddTracking() -> FulfillOrderScreen {
        selectTracking().pop()
        return self
    }

    func completeFulfillment() -> SingleOrderScreen {
        markOrderCompleteButton.tap()
        XCTAssert(XCUIApplication().staticTexts["Order marked as fulfilled"].waitForExistence(timeout: 3))
        return SingleOrderScreen()
    }

    @discardableResult
    func goBackToSingleOrderScreen() -> SingleOrderScreen {
        pop()
        return SingleOrderScreen()
    }

    private func selectTracking() -> AddTrackingScreen {
           XCTAssert(addTrackingButton.waitForExistence(timeout: 2))
           addTrackingButton.tap()
           return AddTrackingScreen()
    }
}
