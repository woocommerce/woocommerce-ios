import XCTest

public final class ReviewsScreen: BaseScreen {

    struct ElementStringIDs {
        static let markAllAsReadButton = "reviews-mark-all-as-read-button"
    }

    public let tabBar = TabNavComponent()
    private let markAllAsReadButton: XCUIElement

    static var isVisible: Bool {
        let markAllAsReadButton = XCUIApplication().buttons[ElementStringIDs.markAllAsReadButton]
        return markAllAsReadButton.exists && markAllAsReadButton.isHittable
    }

    init() {
        markAllAsReadButton = XCUIApplication().buttons[ElementStringIDs.markAllAsReadButton]
        super.init(element: markAllAsReadButton)
    }

    @discardableResult
    public func selectReview(atIndex index: Int) -> SingleReviewScreen {
        XCUIApplication().tables.cells.element(boundBy: index).tap()
        return SingleReviewScreen()
    }
}
