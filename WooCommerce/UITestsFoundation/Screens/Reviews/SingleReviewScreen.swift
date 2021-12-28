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
    public func goBackToReviewsScreen() throws -> ReviewsScreen {
        pop()
        return try ReviewsScreen()
    }

    @discardableResult
    public func verifyReviewOnSingleProductScreen(review: ReviewData) throws -> Self {
        let reviewVisibilityCount = app.tables.textViews.matching(NSPredicate(format: "identifier == %@", "single-review-comment")).firstMatch.exists

        app.assertTextVisibilityCount(text: review.reviewer)
        app.assertTextVisibilityCount(text: review.product_name ?? "")
        XCTAssertTrue(reviewVisibilityCount, "Expecting review to appear once, appeared \(reviewVisibilityCount) times instead!")

        return self
    }

    @discardableResult
    public func verifySingleReviewScreenLoaded() throws -> Self {
        XCTAssertTrue(isLoaded)
        return self
    }
}
