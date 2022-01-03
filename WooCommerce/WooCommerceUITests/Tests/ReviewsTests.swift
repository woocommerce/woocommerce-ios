import UITestsFoundation
import XCTest

final class ReviewsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()
    }

    func testReviewsScreenLoad() throws {
        let reviews = try GetMocks.readReviewsData()

        // Extra step needed to get products mock data to appear on Reviews screen
        try TabNavComponent()
            .gotoProductsScreen()

        try TabNavComponent().gotoReviewsScreen()
            .verifyReviewsScreenLoaded()
            .verifyReviewListOnReviewsScreen(reviews: reviews)
            .selectReview(byReviewer: reviews[0].reviewer)
            .verifySingleReviewScreenLoaded()
            .verifyReviewOnSingleProductScreen(review: reviews[0])
            .goBackToReviewsScreen()
            .verifyReviewsScreenLoaded()
    }
}
