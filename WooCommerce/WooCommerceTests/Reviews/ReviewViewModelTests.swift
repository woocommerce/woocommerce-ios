import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ReviewViewModelTests: XCTestCase {
    private let mocks = MockReviews()
    private var subject: ReviewViewModel!
    private var review: ProductReview!

    override func setUp() {
        super.setUp()
        review = mocks.review()
        subject = ReviewViewModel(review: review, product: nil)
    }

    override func tearDown() {
        subject = nil
        review = nil
        super.tearDown()
    }

    func testReviewViewModelReturnsSubject() {
        XCTAssertEqual(subject.subject, subjectWithoutProduct())
    }
}


private extension ReviewViewModelTests {
    private func subjectWithoutProduct() -> String {
        return String(format: Strings.subjectFormat, mocks.reviewer, "")
    }

    enum Strings {
        static let subjectFormat = NSLocalizedString(
            "%@ left a review on %@",
            comment: "Review title. Reads as {Review author} left a review on {Product}.")
    }
}
