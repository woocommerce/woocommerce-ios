import UITestsFoundation
import XCTest

final class ReviewsTests: XCTestCase {

    override func setUpWithError() throws {
        try skipTillReviewMenuFixed()

        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()

        // Extra step needed to get products mock data to appear on Reviews screen
        // GH Issue: https://github.com/woocommerce/woocommerce-ios/issues/1907
        try TabNavComponent()
            .goToProductsScreen()

        try TabNavComponent()
            .goToMenuScreen()
            .goToReviewsScreen()
    }

    func testReviewsScreenLoad() throws {
        try skipTillReviewMenuFixed()

        let reviews = try GetMocks.readReviewsData()

        try ReviewsScreen()
            .verifyReviewsScreenLoaded()
            .verifyReviewList(reviews: reviews)
            .selectReview(byReviewer: reviews[0].reviewer)
            .verifySingleReviewScreenLoaded()
            .verifyReview(review: reviews[0])
            .goBackToReviewsScreen()
            .verifyReviewsScreenLoaded()
    }

    func skipTillReviewMenuFixed(file: StaticString = #file, line: UInt = #line) throws {
        try XCTSkipIf(true,
            """
            Skipping test because of the reviews menu does not appear on first load. See: https://github.com/woocommerce/woocommerce-ios/issues/5872
            """, file: file, line: line)
    }
}
