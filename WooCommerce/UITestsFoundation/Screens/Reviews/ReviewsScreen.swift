import ScreenObject
import XCTest

public final class ReviewsScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

    static var isVisible: Bool {
        (try? ReviewsScreen().isLoaded) ?? false
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // TODO: the following line results in time out error.
            // "reviews-open-menu-button" button isn't shown when there are no unread reviews, but we cannot pass an empty array here
            expectedElementGetters: [ { $0.buttons["reviews-open-menu-button"] } ],
            app: app
        )
    }

    @discardableResult
    public func selectReview(atIndex index: Int) throws -> SingleReviewScreen {
        app.tables.cells.element(boundBy: index).tap()
        return try SingleReviewScreen()
    }

    @discardableResult
    public func selectReview(byReviewer reviewer: String) throws -> SingleReviewScreen {
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
