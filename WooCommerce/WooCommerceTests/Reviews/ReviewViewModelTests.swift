import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ReviewViewModelTests: XCTestCase {
    private let mocks = MockReviews()
    private var subject: ReviewViewModel!
    private var review: ProductReview!
    private var product: Product!

    override func setUp() {
        super.setUp()
        review = mocks.review()
        product = mocks.product()
        subject = ReviewViewModel(review: review, product: product)
    }

    override func tearDown() {
        subject = nil
        review = nil
        product = nil
        super.tearDown()
    }

    func testReviewViewModelReturnsSubjectWithoutProductNameWhenProductIsNil() {
        let viewModel = ReviewViewModel(review: review, product: nil)
        XCTAssertEqual(viewModel.subject, reviewWithoutProduct())
    }

    func testReviewViewModelReturnsSubjectWithProductName() {
        XCTAssertEqual(subject.subject, reviewWithProduct())
    }

    func testSnippetReturnsExpectation() {
        XCTAssertEqual(subject.snippet?.string, "Pending Review ∙ " + NSAttributedString(string: review.review.strippedHTML).trimNewlines().string)
    }

    func testRatingMatchesExpectation() {
        XCTAssertEqual(subject.rating, review.rating)
    }

    func testIconColorMatchesExpectation() {
        XCTAssertEqual(subject.notIconColor, StyleManager.wooGreyMid)
    }
}


private extension ReviewViewModelTests {
    private func reviewWithoutProduct() -> String {
        return String(format: Strings.subjectFormat, mocks.reviewer, "")
    }

    private func reviewWithProduct() -> String {
        return String(format: Strings.subjectFormat, mocks.reviewer, mocks.productName)
    }

    enum Strings {
        static let subjectFormat = NSLocalizedString(
            "%@ left a review on %@",
            comment: "Review title. Reads as {Review author} left a review on {Product}.")
    }
}
