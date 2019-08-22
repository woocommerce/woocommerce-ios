import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ProductReviewStore Unit Tests
///
final class ProductReviewStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID = 123

    /// Testing ReviewID
    ///
    private let sampleReviewID = 173

    /// Testing ProductID
    ///
    private let sampleProductID = 282

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
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }


    // MARK: - ProductReviewAction.synchronizeProductReviews

    /// Verifies that ProductReviewAction.synchronizeProductReviews effectively persists any retrieved product reviews.
    ///
    func testRetrieveProductReviewsEffectivelyPersistsRetrievedProductReviews() {
        let expectation = self.expectation(description: "Retrieve product review list")
        let productReviewStore = ProductReviewStore(dispatcher: dispatcher,
                                                    storageManager: storageManager,
                                                    network: network)

        network.simulateResponse(requestUrlSuffix: "products/reviews", filename: "reviews-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ProductReview.self), 0)

        let action = ProductReviewAction.synchronizeProductReviews(siteID: sampleSiteID,
                                                                   pageNumber: defaultPageNumber,
                                                                   pageSize: defaultPageSize) { error in
                                                                    XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ProductReview.self), 2)
                                                                    XCTAssertNil(error)

                                                                    expectation.fulfill()
        }

        productReviewStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
