import XCTest
@testable import Networking


/// ProductReviewsRemoteTests
///
final class ProductReviewsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Dummy Product ID
    ///
    private let sampleReviewID: Int64 = 173

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load all product reviews tests

    /// Verifies that loadAllProductReviews properly parses the `reviews-all` sample response.
    ///
    func testLoadAllProductReviewsProperlyReturnsParsedProductReviews() throws {
        // Given
        let remote = ProductReviewsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")

        // When
        let result: Result<[ProductReview], Error> = waitFor { promise in
            remote.loadAllProductReviews(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let reviews = try XCTUnwrap(result.get())
        XCTAssertEqual(reviews.count, 2)

        // Assert proper parsing of reviewer_avatar_urls
        reviews.forEach {
            XCTAssertNotNil($0.reviewerAvatarURL)
        }
    }

    /// Verifies that loadAllProductReviews properly relays Networking Layer errors.
    ///
    func testLoadAllProductReviewsProperlyRelaysNetwokingErrors() throws {
        // Given
        let remote = ProductReviewsRemote(network: network)

        // When
        let result: Result<[ProductReview], Error> = waitFor { promise in
            remote.loadAllProductReviews(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Tests that loadAllProductReviews can handle responses with missing `reviewer_avatar_urls`.
    ///
    func testLoadAllCanHandleMissingReviewerAvatarURLs() throws {
        // Given
        let remote = ProductReviewsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-missing-avatar-urls")

        // When
        let result: Result<[ProductReview], Error> = waitFor { promise in
            remote.loadAllProductReviews(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let reviews = try XCTUnwrap(result.get())
        XCTAssertEqual(reviews.count, 2)

        // Assert proper parsing of reviewer_avatar_urls
        reviews.forEach {
            XCTAssertNil($0.reviewerAvatarURL)
        }
    }

    // MARK: - Load single product review tests

    /// Verifies that loadProductReview properly parses the `reviews-single` sample response.
    ///
    func testLoadProductReviewProperlyReturnsParsedProductReviews() throws {
        // Given
        let remote = ProductReviewsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "products/reviews/\(sampleReviewID)", filename: "reviews-single")

        // When
        let result: Result<ProductReview, Error> = waitFor { promise in
            remote.loadProductReview(for: self.sampleSiteID, reviewID: self.sampleReviewID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(try result.get())
    }

    /// Verifies that loadProductReview properly relays Networking Layer errors.
    ///
    func testLoadProductReviewProperlyRelaysNetworkingErrors() throws {
        // Given
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Load a single Product Review returns error")

        // When
        var resultMaybe: Result<ProductReview, Error>?
        remote.loadProductReview(for: sampleSiteID, reviewID: sampleReviewID) { aResult in
            resultMaybe = aResult
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertTrue(result.isFailure)
    }


    // MARK: - Update single product review tests

    /// Verifies that updateProductReview properly parses the `reviews-single` sample response.
    ///
    func testUpdateProductReviewProperlyReturnsParsedProductReviews() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Update Product Review status")

        let newStatusKey = "hold"

        network.simulateResponse(requestUrlSuffix: "products/reviews/\(sampleReviewID)", filename: "reviews-single")
        remote.updateProductReviewStatus(for: sampleSiteID,
                                         reviewID: sampleReviewID,
                                         statusKey: newStatusKey) { review, error in
                                            XCTAssertNil(error)
                                            XCTAssertNotNil(review)
                                            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateProductReview properly relays Networking Layer errors.
    ///
    func testUpdateProductReviewProperlyRelaysNetwokingErrors() {
        let remote = ProductReviewsRemote(network: network)
        let expectation = self.expectation(description: "Update a single Product Review returns error")

        let newStatusKey = "hold"

        remote.updateProductReviewStatus(for: sampleSiteID,
                                         reviewID: sampleReviewID,
                                         statusKey: newStatusKey) { review, error in
                                            XCTAssertNil(review)
                                            XCTAssertNotNil(error)
                                            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
