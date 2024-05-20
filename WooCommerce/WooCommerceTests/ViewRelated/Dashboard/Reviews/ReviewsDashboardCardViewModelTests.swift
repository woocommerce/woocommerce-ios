import XCTest
import Yosemite
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class ReviewsDashboardCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 1337
    private var stores: MockStoresManager!

    private let sampleReviews: [ProductReview] = [ProductReview.fake().copy(siteID: 1337, reviewID: 1),
                                 ProductReview.fake().copy(siteID: 1337, reviewID: 2),
                                 ProductReview.fake().copy(siteID: 1337, reviewID: 3)]

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_reviews_are_loaded_from_storage_when_available() async {
        // Given
        let viewModel = ReviewsDashboardCardViewModel(siteID: sampleSiteID,
                                                      stores: stores,
                                                      storageManager: storageManager)

        insertReviews(sampleReviews)

        // When
        stores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleReviews))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        waitUntil {
            viewModel.data.count == 3
        }
    }
}


extension ReviewsDashboardCardViewModelTests {
    func insertReviews(_ readOnlyReviews: [ProductReview]) {
        readOnlyReviews.forEach { review in
            let newReview = storage.insertNewObject(ofType: StorageProductReview.self)
            newReview.update(with: review)
        }
        storage.saveIfNeeded()
    }
}
