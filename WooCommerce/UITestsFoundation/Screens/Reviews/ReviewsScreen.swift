import ScreenObject
import XCTest

public final class ReviewsScreen: ScreenObject {

    public let tabBar = TabNavComponent()

    static var isVisible: Bool {
        (try? ReviewsScreen().isLoaded) ?? false
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.buttons["reviews-mark-all-as-read-button"] } ],
            app: app
        )
    }

    @discardableResult
    public func selectReview(atIndex index: Int) throws -> SingleReviewScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleReviewScreen()
    }
}
