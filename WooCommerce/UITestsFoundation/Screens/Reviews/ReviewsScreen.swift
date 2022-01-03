import ScreenObject
import XCTest

public final class ReviewsScreen: ScreenObject {

    // TODO: Remove force `try` once `ScreenObject` migration is completed
    public let tabBar = try! TabNavComponent()

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
    public func verifyReviewListOnReviewsScreen(reviews: [ReviewData]) throws -> Self {
        app.assertTextVisibilityCount(textToFind: reviews[0].reviewer)
        app.assertCorrectCellCountDisplayed(expectedCount: reviews.count, actualCount: app.tables.cells.count)
        app.assertTwoTextsAppearOnSameLabel(firstSubstring: reviews[0].reviewer, secondSubstring: reviews[0].product_name!)

        return self
    }
}
