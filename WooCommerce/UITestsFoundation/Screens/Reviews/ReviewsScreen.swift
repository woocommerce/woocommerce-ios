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

    func verifyProductNameForReview(reviewer: String, product: String) throws -> Bool {
        let reviewerPredicate = NSPredicate(format: "label CONTAINS[c] %@", reviewer)
        let productPredicate = NSPredicate(format: "label CONTAINS[c] %@", product)
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [reviewerPredicate, productPredicate])

        return XCUIApplication().staticTexts.containing(predicateCompound).count == 1
    }

    @discardableResult
    public func verifyReviewListOnReviewsScreen(reviews: [ReviewData]) throws -> Self {
        app.assertTextVisibilityCount(text: reviews[0].reviewer)
        XCTAssertEqual(reviews.count, app.tables.cells.count, "Expecting \(reviews.count) reviews, got \(app.tables.cells.count) instead!")
        XCTAssertTrue(try verifyProductNameForReview(reviewer: reviews[0].reviewer, product: reviews[0].product_name!), "Product does not appear on review!")

        return self
    }
}
