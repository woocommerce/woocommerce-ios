import Foundation
import XCTest

final class SingleOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let summaryTitleLabel = "summary-table-view-cell-title-label"
        static let productsSection = "Product" // TODO: add accessibility indicator. Using "Product" from Accessibility inspector for the moment.
        static let paymentsSection = "Product Total" // TODO: add accessibility indicator Using "Product Total" from Accessibility inspector for the  moment.
        static let customerSection = "Shipping details" // TODO: add accessibility indicator. Using "Shipping details" from Accessibility inspector for the moment.
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
        productsSection = XCUIApplication().staticTexts[ElementStringIDs.productsSection]
        paymentsSection = XCUIApplication().staticTexts[ElementStringIDs.paymentsSection]
        customerSection = XCUIApplication().staticTexts[ElementStringIDs.customerSection]

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
