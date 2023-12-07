import XCTest
@testable import Networking


final class ProductReviewListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductReview Fields are parsed correctly.
    ///
    func test_ProductReview_fields_are_properly_parsed() async {
        let productReviews = await mapLoadAllProductReviewsResponse()
        XCTAssertEqual(productReviews.count, 2)

        let firstProductReview = productReviews[0]

        XCTAssertEqual(firstProductReview.siteID, dummySiteID)
        XCTAssertEqual(firstProductReview.reviewID, 173)
        XCTAssertEqual(firstProductReview.productID, 32)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-08-20T06:06:29")
        XCTAssertEqual(firstProductReview.dateCreated, dateCreated)

        XCTAssertEqual(firstProductReview.status, ProductReviewStatus.approved)

        XCTAssertEqual(firstProductReview.reviewer, "somereviewer")
        XCTAssertEqual(firstProductReview.reviewerEmail, "somewhere@intheinternet.com")
        XCTAssertEqual(firstProductReview.review, "<p>The fancy chair gets only three stars</p>\n")
        XCTAssertEqual(firstProductReview.rating, 3)

        XCTAssertFalse(firstProductReview.verified)
    }

    /// Verifies that all of the ProductReview Fields are parsed correctly.
    ///
    func test_ProductReview_fields_are_properly_parsed_when_response_has_no_data_envelope() async {
        let productReviews = await mapLoadAllProductReviewsResponseWithoutDataEnvelope()
        XCTAssertEqual(productReviews.count, 2)

        let firstProductReview = productReviews[0]

        XCTAssertEqual(firstProductReview.siteID, dummySiteID)
        XCTAssertEqual(firstProductReview.reviewID, 173)
        XCTAssertEqual(firstProductReview.productID, 32)

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-08-20T06:06:29")
        XCTAssertEqual(firstProductReview.dateCreated, dateCreated)

        XCTAssertEqual(firstProductReview.status, ProductReviewStatus.approved)

        XCTAssertEqual(firstProductReview.reviewer, "somereviewer")
        XCTAssertEqual(firstProductReview.reviewerEmail, "somewhere@intheinternet.com")
        XCTAssertEqual(firstProductReview.review, "<p>The fancy chair gets only three stars</p>\n")
        XCTAssertEqual(firstProductReview.rating, 3)

        XCTAssertFalse(firstProductReview.verified)
    }
}


/// Private Methods.
///
private extension ProductReviewListMapperTests {

    /// Returns the ProducReviewtListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductReviews(from filename: String) async -> [ProductReview] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! await ProductReviewListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductListMapper output upon receiving `reviews-all`
    ///
    func mapLoadAllProductReviewsResponse() async -> [ProductReview] {
        await mapProductReviews(from: "reviews-all")
    }

    /// Returns the ProductListMapper output upon receiving `reviews-all-without-data`
    ///
    func mapLoadAllProductReviewsResponseWithoutDataEnvelope() async -> [ProductReview] {
        await mapProductReviews(from: "reviews-all-without-data")
    }
}
