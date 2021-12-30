import XCTest
import Foundation

public final class SingleOrderScreen: BaseScreen {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    let tabBar = try! TabNavComponent()

    struct ElementStringIDs {
           static let summaryTitleLabel = "summary-table-view-cell-title-label"
           static let productsSection = "single-product-cell"
           static let paymentsSection = "single-order-payment-cell"
           static let customerSection = "customer-shipping-details-address"
       }

       //let tabBar = TabNavComponent()
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
    public func verifySingleOrderScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded())
        return self
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
