import XCTest
@testable import Networking


/// ProductReviewsRemoteTests
///
final class ProductReviewsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Product ID
    ///
    let sampleReviewID = 173

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load all product reviews tests

    /// Verifies that loadAllProductReviews properly parses the `reviews-all` sample response.
    ///
    func testLoadAllProductReviewsProperlyReturnsParsedProductReviews() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Reviews")

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")

        remote.loadAllProductReviews(for: sampleSiteID) { reviews, error in
            XCTAssertNil(error)
            XCTAssertNotNil(reviews)
            XCTAssertEqual(reviews?.count, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductReviews properly relays Networking Layer errors.
    ///
    func testLoadAllProductReviewsProperlyRelaysNetwokingErrors() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Reviews returns error")

        remote.loadAllProductReviews(for: sampleSiteID) { reviews, error in
            XCTAssertNil(reviews)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Load single product review tests

    /// Verifies that loadProductReview properly parses the `reviews-single` sample response.
    ///
    func testLoadProductReviewProperlyReturnsParsedProductReviews() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Load Single Product Reviews")

        network.simulateResponse(requestUrlSuffix: "products/reviews/\(sampleReviewID)", filename: "reviews-single")

        remote.loadProductReview(for: sampleSiteID, reviewID: sampleReviewID) { review, error in
            XCTAssertNil(error)
            XCTAssertNotNil(review)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadProductReview properly relays Networking Layer errors.
    ///
    func testLoadProductReviewProperlyRelaysNetwokingErrors() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Load a single Product Review returns error")

        remote.loadProductReview(for: sampleSiteID, reviewID: sampleReviewID) { review, error in
            XCTAssertNil(review)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
