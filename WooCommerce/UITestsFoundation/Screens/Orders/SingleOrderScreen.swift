import XCTest

public final class SingleOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let summaryTitleLabel = "summary-table-view-cell-title-label"
    }

    let tabBar = TabNavComponent()
    private let summaryTitleLabel: XCUIElement

    static var isVisible: Bool {
        let summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        return summaryTitleLabel.exists && summaryTitleLabel.isHittable
    }

    init() {
        summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        super.init(element: summaryTitleLabel)
    }

    @discardableResult
    public func goBackToOrdersScreen() -> OrdersScreen {
        pop()
        return OrdersScreen()
    }
}
