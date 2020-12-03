import XCTest

@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductReviewStore Unit Tests
///
final class ProductReviewStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Store
    ///
    private var store: ProductReviewStore!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing ReviewID
    ///
    private let sampleReviewID: Int64 = 173

    /// Testing ProductID
    ///
    private let sampleProductID: Int64 = 32

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        store = ProductReviewStore(dispatcher: dispatcher,
                                   storageManager: storageManager,
                                   network: network)
    }

    override func tearDown() {
        store = nil
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }


    // MARK: - ProductReviewAction.synchronizeProductReviews

    /// Verifies that ProductReviewAction.synchronizeProductReviews effectively persists any retrieved product reviews.
    ///
    func test_retrieve_product_reviews_effectively_persists_retrieved_product_reviews() {
        let expectation = self.expectation(description: "Retrieve product review list")

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 0)

        let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID,
                                                                   pageNumber: defaultPageNumber,
                                                                   pageSize: defaultPageSize) { error in
                                                                    XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)
                                                                    XCTAssertNil(error)

                                                                    expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductReviewAction.synchronizeProductReviews` effectively persists all of the fields
    /// correctly across all of the related `ProductReview` entities
    ///
    func test_retrieve_product_reviews_effectively_persists_product_review_fields() {
        let expectation = self.expectation(description: "Persist product review list")

        let remoteProductReview = sampleProductReview()

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 0)

        let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedProductReview = self.viewStorage.loadProductReview(siteID: self.sampleSiteID, reviewID: self.sampleReviewID)
            let readOnlyStoredProductReview = storedProductReview?.toReadOnly()
            XCTAssertNotNil(storedProductReview)
            XCTAssertNotNil(readOnlyStoredProductReview)
            XCTAssertEqual(readOnlyStoredProductReview, remoteProductReview)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductReviewAction.synchronizeProductReviews` for the first page deletes stored Product Reviews for the given site ID.
    ///
    func test_syncing_product_reviews_on_the_first_page_resets_stored_product_reviews() {

        // Given
        let reviewID1: Int64 = 1
        let reviewID2: Int64 = 2
        let productReviews = [sampleProductReview(reviewID: reviewID1), sampleProductReview(reviewID: reviewID2)]
        store.upsertStoredProductReviews(readOnlyProductReviews: productReviews,
                                              in: viewStorage,
                                              siteID: sampleSiteID)

        // When
        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)

        waitForExpectation { exp in
            let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID,
                                                                       pageNumber: defaultPageNumber,
                                                                       pageSize: defaultPageSize) { error in

                // Then
                XCTAssertNil(error)

                // The previously upserted Product Reviews should be deleted.
                let storedProductReview1 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID1)
                XCTAssertNil(storedProductReview1)

                let storedProductReview2 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID2)
                XCTAssertNil(storedProductReview2)

                exp.fulfill()
            }
            store.onAction(action)
        }
    }

    /// Verifies that `ProductReviewAction.synchronizeProductReviews` after the first page does not delete stored Product Reviews for the given
    /// site ID.
    ///
    func test_syncing_product_reviews_after_the_first_page() {

        // Given
        let reviewID1: Int64 = 1
        let reviewID2: Int64 = 2
        let productReviews = [sampleProductReview(reviewID: reviewID1), sampleProductReview(reviewID: reviewID2)]
        store.upsertStoredProductReviews(readOnlyProductReviews: productReviews,
                                              in: viewStorage,
                                              siteID: sampleSiteID)

        // When
        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)

        waitForExpectation { exp in
            let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID,
                                                                       pageNumber: 3,
                                                                       pageSize: defaultPageSize) { error in

                // Then
                XCTAssertNil(error)

                // The previously upserted Product Reviews should stay in storage.
                let storedProductReview1 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID1)
                XCTAssertNotNil(storedProductReview1)

                let storedProductReview2 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID2)
                XCTAssertNotNil(storedProductReview2)

                XCTAssertGreaterThan(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)

                exp.fulfill()
            }
            store.onAction(action)
        }
    }

    /// Verifies that `ProductReviewAction.synchronizeProductReviews` for the first page does not delete stored Product Reviews if the API call fails.
    ///
    func test_syncing_product_reviews_on_the_first_page_does_not_delete_stored_product_reviews_upon_response_error() {

        // Given
        let reviewID1: Int64 = 1
        let reviewID2: Int64 = 2
        let productReviews = [sampleProductReview(reviewID: reviewID1), sampleProductReview(reviewID: reviewID2)]
        store.upsertStoredProductReviews(readOnlyProductReviews: productReviews,
                                              in: viewStorage,
                                              siteID: sampleSiteID)

        // When
        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "generic_error")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)

        waitForExpectation { exp in
            let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID,
                                                                       pageNumber: defaultPageNumber,
                                                                       pageSize: defaultPageSize) { error in
                // Then
                XCTAssertNotNil(error)

                // The previously upserted Product Reviews should stay in storage.
                let storedProductReview1 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID1)
                XCTAssertNotNil(storedProductReview1)

                let storedProductReview2 = self.viewStorage.loadProductReview(
                    siteID: self.sampleSiteID,
                    reviewID: reviewID2)
                XCTAssertNotNil(storedProductReview2)

                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)

                exp.fulfill()
            }
            store.onAction(action)
        }
    }

    /// Tests that reviews with no `reviewer_avatar_urls` can be saved by Core Data.
    ///
    func test_it_can_save_reviews_with_no_avatar_URLs() {
        // Given
        let expectation = self.expectation(description: "Persist product review list")

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-missing-avatar-urls")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 0)

        var resultError: Error?
        let action = ProductReviewAction.synchronizeProductReviews(
            siteID: sampleSiteID,
            pageNumber: defaultPageNumber,
            pageSize: defaultPageSize) { error in
                resultError = error
                expectation.fulfill()
        }

        // When
        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertNil(resultError)

        let review = viewStorage.loadProductReview(siteID: sampleSiteID, reviewID: sampleReviewID)?.toReadOnly()
        XCTAssertNotNil(review)
        XCTAssertNil(review?.reviewerAvatarURL)
    }

    /// Verifies that ProductReviewAction.synchronizeProductReviews returns an error whenever there is an error response from the backend.
    ///
    func test_retrieve_product_reviews_returns_error_upon_response_error() {
        let expectation = self.expectation(description: "Retrieve product reviews error response")

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "generic_error")
        let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that ProductReviewAction.synchronizeProductReviews returns an error whenever there is no backend response.
    ///
    func test_retrieve_product_reviews_returns_error_upon_empty_response() {
        let expectation = self.expectation(description: "Retrieve product reviews empty response")

        let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - ProductReviewAction.retrieveProductReview

    /// Verifies that `ProductReviewAction.retrieveProductReview` returns the expected `ProductReview`.
    ///
    func test_retrieve_single_product_review_returns_expected_fields() {
        let expectation = self.expectation(description: "Retrieve single product review")
        let remoteProductReview = sampleProductReview()

        network.simulateResponse(requestUrlSuffix: "products/reviews/173", filename: "reviews-single")
        let action = ProductReviewAction.retrieveProductReview(siteID: sampleSiteID, reviewID: sampleReviewID) { (productReview, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(productReview)
            XCTAssertEqual(productReview, remoteProductReview)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductReviewAction.retrieveProductReview` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieve_single_product_review_returns_error_upon_reponse_error() {
        let expectation = self.expectation(description: "Retrieve single product review error response")

        network.simulateResponse(requestUrlSuffix: "products/reviews/173", filename: "generic_error")
        let action = ProductReviewAction.retrieveProductReview(siteID: sampleSiteID, reviewID: sampleReviewID) { (product, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductReviewAction.retrieveProductReview` returns an error whenever there is no backend response.
    ///
    func test_retrieve_single_product_review_returns_error_upon_empty_response() {
        let expectation = self.expectation(description: "Retrieve single product review empty response")

        let action = ProductReviewAction.retrieveProductReview(siteID: sampleSiteID, reviewID: sampleReviewID) { (product, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(product)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ProductReviewAction.retrieveProductReview` returns an error whenever there is no backend response.
    ///
    func test_retrieve_single_product_review_deletes_the_review_when_receiving_a_404_response() throws {
        // Given
        let storageReview = viewStorage.insertNewObject(ofType: StorageProductReview.self)
        storageReview.update(with: sampleProductReview())
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductReview.self), 1)

        // When
        var resultMaybe: (review: Yosemite.ProductReview?, error: Error?)?
        waitForExpectation { expectation in
            let action = ProductReviewAction.retrieveProductReview(siteID: sampleSiteID, reviewID: sampleReviewID) { (review, error) in
                resultMaybe = (review: review, error: error)
                expectation.fulfill()
            }
            store.onAction(action)
        }

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertNotNil(result.error)
        XCTAssertNil(result.review)

        guard case NetworkError.notFound = try XCTUnwrap(result.error) else {
            XCTFail("Expected a notFound NetworkError")
            return
        }

        // The existing ProductReview should be deleted
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductReview.self), 0)
    }


    // MARK: - ProductReviewAction.resetStoredProductReviews

    /// Verifies that `ProductReviewAction.resetStoredProductReviews` deletes the Products from Storage
    ///
    func test_reset_stored_product_reviews_effectively_nukes_the_products_cache() {
        let expectation = self.expectation(description: "Stored Product reviews Reset")
        let action = ProductReviewAction.resetStoredProductReviews() {
            self.store.upsertStoredProductReviews(readOnlyProductReviews: [self.sampleProductReview()], in: self.viewStorage, siteID: self.sampleSiteID)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 1)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ProductReviewStore.upsertStoredProductReview

    /// Verifies that `ProductReviewStore.upsertStoredProductReview` does not produce duplicate entries.
    ///
    func test_update_stored_product_review_effectively_updates_preexistant_product_review() {

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 0)

        store.upsertStoredProductReviews(readOnlyProductReviews: [sampleProductReview()], in: viewStorage, siteID: sampleSiteID)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 1)

        store.upsertStoredProductReviews(readOnlyProductReviews: [sampleProductReviewMutated()], in: viewStorage, siteID: sampleSiteID)
        let storageProductReview1 = viewStorage.loadProductReview(siteID: sampleSiteID, reviewID: sampleReviewID)
        XCTAssertEqual(storageProductReview1?.toReadOnly(), sampleProductReviewMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 1)
    }
}


// MARK: - Private Helpers
//
private extension ProductReviewStoreTests {

    func sampleProductReview(reviewID: Int64? = nil) -> Networking.ProductReview {
        return Networking.ProductReview(siteID: sampleSiteID,
                                        reviewID: reviewID ?? sampleReviewID,
                                        productID: sampleProductID,
                                        dateCreated: Date(),
                                        statusKey: "hold",
                                        reviewer: "someone",
                                        reviewerEmail: "somewhere@theinternet.com",
                                        reviewerAvatarURL: "http://animage.com",
                                        review: "Meh",
                                        rating: 1,
                                        verified: true)
    }

    func sampleProductReviewMutated() -> Networking.ProductReview {
        return Networking.ProductReview(siteID: sampleSiteID,
                                        reviewID: sampleReviewID,
                                        productID: sampleProductID,
                                        dateCreated: Date(),
                                        statusKey: "hold",
                                        reviewer: "someone else mutated",
                                        reviewerEmail: "somewhere@theinternet.com",
                                        reviewerAvatarURL: "http://animage.com",
                                        review: "Meh",
                                        rating: 1,
                                        verified: true)
    }
}
