import Foundation
import XCTest

final class SingleOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let summaryTitleLabel = "summary-table-view-cell-title-label"
        static let fulfillmentButton = "begin-fulfillment-button"
        static let addTrackingButton = "order-details-add-tracking-button"
        static let addNoteButton = "add-order-note-button"
    }

    let tabBar = TabNavComponent()
    private let summaryTitleLabel: XCUIElement
    private let fulfillmentButton: XCUIElement
    private let addTrackingButton: XCUIElement
    private let addNoteButton: XCUIElement

    static var isVisible: Bool {
        let summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        return summaryTitleLabel.exists && summaryTitleLabel.isHittable
    }

    init() {
        summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        fulfillmentButton = XCUIApplication().buttons[ElementStringIDs.fulfillmentButton]
        addTrackingButton = XCUIApplication().cells[ElementStringIDs.addTrackingButton]
        addNoteButton = XCUIApplication().cells[ElementStringIDs.addNoteButton]
        super.init(element: summaryTitleLabel)
    }

    func beginFulfillment() -> FulfillOrderScreen {
        fulfillmentButton.tap()
        return FulfillOrderScreen()
    }

    func addTracking(withCarrier carrier: String, andTrackingNumber trackingNumber: String) -> SingleOrderScreen {
        selectAddTracking().addTrackingInfo(carrier: carrier, trackingNumber: trackingNumber)
        return self
    }

    func selectAddNote() -> OrderNoteScreen {
        addNoteButton.tap()
        return OrderNoteScreen()
    }

    @discardableResult
    func goBackToOrdersScreen() -> OrdersScreen {
        pop()
        return OrdersScreen()
    }

    private func selectAddTracking() -> AddTrackingScreen {
        addTrackingButton.tap()
        return AddTrackingScreen()
    }
}
