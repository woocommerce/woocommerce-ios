import XCTest

public final class SingleOrderScreen: BaseScreen {

    struct ElementStringIDs {
        static let summaryTitleLabel = "summary-table-view-cell-title-label"
    }

    let tabBar = TabNavComponent()
    private let summaryTitleLabel: XCUIElement

    init() {
        summaryTitleLabel = XCUIApplication().staticTexts[ElementStringIDs.summaryTitleLabel]
        super.init(element: summaryTitleLabel)
    }

    @discardableResult
    public func goBackToOrdersScreen() throws -> OrdersScreen {
        pop()
        return try OrdersScreen()
    }
}
