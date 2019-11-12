import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ReviewViewModelTests: XCTestCase {
    private let mocks = MockReviews()
    private var subject: ReviewViewModel!
    private var review: ProductReview!
    private var product: Product!
    private var notification: Note!

    override func setUp() {
        super.setUp()
        review = mocks.review()
        product = mocks.product()
        notification = mocks.emptyNotification()
        subject = ReviewViewModel(review: review,
                                  product: product,
                                  notification: notification)
    }

    override func tearDown() {
        subject = nil
        review = nil
        product = nil
        super.tearDown()
    }

    func testReviewViewModelReturnsSubjectWithoutProductNameWhenProductIsNil() {
        let viewModel = ReviewViewModel(review: review, product: nil, notification: nil)
        XCTAssertEqual(viewModel.subject, reviewWithoutProduct())
    }

    func testReviewViewModelReturnsSubjectWithProductName() {
        XCTAssertEqual(subject.subject, reviewWithProduct())
    }

    func testReviewViewModelReturnsSubjectWithAnonymousForUnknownReviewerName() {
        let viewModel = ReviewViewModel(review: mocks.anonyousReview(), product: product, notification: notification)

        let reviewSubject = viewModel.subject

        XCTAssertTrue(reviewSubject!.contains("Someone"))
    }

    func testNotIconIsCommentIcon() {
        XCTAssertEqual(subject.notIcon, "\u{f300}")
    }

    func testSnippetReturnsExpectation() {
        XCTAssertEqual(subject.snippet?.string, "Pending Review ∙ " + NSAttributedString(string: review.review.strippedHTML).trimNewlines().string)
    }

    func testRatingMatchesExpectation() {
        XCTAssertEqual(subject.rating, review.rating)
    }

    func testReadMatchesNotificationRead() {
        XCTAssertEqual(subject.read, notification.read)
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
