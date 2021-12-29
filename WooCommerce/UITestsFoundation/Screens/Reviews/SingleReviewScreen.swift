import ScreenObject
import XCTest

public final class SingleReviewScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable opening_brace
                { $0.buttons["single-review-spam-button"] },
                { $0.buttons["single-review-trash-button"] },
                { $0.buttons["single-review-approval-button"] }
                // swiftlint:enable opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func verifySingleReviewScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }

    @discardableResult
    public func goBackToReviewsScreen() throws -> ReviewsScreen {
        pop()
        return try ReviewsScreen()
    }

    @discardableResult
    public func verifyReviewOnSingleProductScreen(review: ReviewData) throws -> Self {
        let reviewExistsOnScreen = app.tables.textViews.matching(NSPredicate(format: "identifier == %@", "single-review-comment")).firstMatch.exists

        app.assertTextVisibilityCount(textToFind: review.reviewer)
        app.assertTextVisibilityCount(textToFind: review.product_name ?? "")
        XCTAssertTrue(reviewExistsOnScreen, "Review does not exist on screen!")

        return self
    }
}
