import Foundation
import XCTest

final class ShippingCarriersScreen: BaseScreen {

    struct ElementStringIDs {
        static let shippingCarriersTable = "shipping-carriers-table"
    }

    private let shippingCarriersTable: XCUIElement

    static var isVisible: Bool {
        let shippingCarriersTable = XCUIApplication().buttons[ElementStringIDs.shippingCarriersTable]
        return shippingCarriersTable.exists && shippingCarriersTable.isHittable
    }

    init() {
        shippingCarriersTable = XCUIApplication().tables[ElementStringIDs.shippingCarriersTable]
        super.init(element: shippingCarriersTable)
    }

    @discardableResult
    func selectShippingCarrier(withName name: String) -> AddTrackingScreen {
        shippingCarriersTable.cells.staticTexts[name].tap()
        return AddTrackingScreen()
    }
}
