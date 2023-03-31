import ScreenObject
import XCTest

public final class ReviewsScreen: ScreenObject {

    public let tabBar: TabNavComponent

    static var isVisible: Bool {
        (try? ReviewsScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent(app: app)

        try super.init(
            expectedElementGetters: [ { $0.tables["reviews-table"] } ],
            app: app
        )
    }

    @discardableResult
    public func tapReview(atIndex index: Int) throws -> SingleReviewScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleReviewScreen()
    }

    @discardableResult
    public func tapReview(byReviewer reviewer: String) throws -> SingleReviewScreen {
        let reviewerPredicate = NSPredicate(format: "label CONTAINS[c] %@", reviewer)
        app.staticTexts.containing(reviewerPredicate).firstMatch.tap()

        return try SingleReviewScreen()
    }

    @discardableResult
    public func verifyReviewsScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    @discardableResult
    public func verifyReviewList(reviews: [ReviewData]) throws -> Self {
        app.assertTextVisibilityCount(textToFind: reviews[0].reviewer, expectedCount: 1)
        app.assertLabelContains(firstSubstring: reviews[0].reviewer, secondSubstring: reviews[0].product_name!)
        XCTAssertEqual(reviews.count, app.tables.cells.count, "Expecting '\(reviews.count)' reviews, got '\(app.tables.cells.count)' instead!")

        return self
    }
}
