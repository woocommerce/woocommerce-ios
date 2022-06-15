import UITestsFoundation
import XCTest

final class ReviewsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()

        // Extra step needed to get products mock data to appear on Reviews screen
        // GH Issue: https://github.com/woocommerce/woocommerce-ios/issues/1907
        try TabNavComponent()
            .goToProductsScreen()
    }

    func test_load_reviews_screen() throws {
        let reviews = try GetMocks.readReviewsData()

        try TabNavComponent().goToMenuScreen()
            .goToReviewsScreen()
            .verifyReviewsScreenLoaded()
            .verifyReviewList(reviews: reviews)
            .selectReview(byReviewer: reviews[0].reviewer)
            .verifySingleReviewScreenLoaded()
            .verifyReview(review: reviews[0])
            .goBackToReviewsScreen()
            .verifyReviewsScreenLoaded()
    }
}
