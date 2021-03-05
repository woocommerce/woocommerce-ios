import Foundation
import XCTest

final class SingleOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let summaryTitleLabel = "summary-table-view-cell-title-label"
        static let productsSection = "single-product-cell"
        static let paymentsSection = "single-order-payment-cell"
        static let customerSection = "customer-shipping-details-address"
    }

    let tabBar = TabNavComponent()
    private let summaryTitleLabel: XCUIElement
    private let productsSection: XCUIElement
    private let paymentsSection: XCUIElement
    private let customerSection: XCUIElement

    static var isVisible: Bool {
        let summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        return summaryTitleLabel.exists && summaryTitleLabel.isHittable
    }

    init() {
        summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        productsSection = XCUIApplication().cells[ElementStringIDs.productsSection]
        paymentsSection = XCUIApplication().cells[ElementStringIDs.paymentsSection]
        customerSection = XCUIApplication().cells[ElementStringIDs.customerSection]

        super.init(element: summaryTitleLabel)
        
        XCTAssert(productsSection.exists)
        XCTAssert(paymentsSection.exists)
        XCTAssert(customerSection.exists)
    }

    @discardableResult
    func goBackToOrdersScreen() -> OrdersScreen {
        pop()
        return OrdersScreen()
    }
}
